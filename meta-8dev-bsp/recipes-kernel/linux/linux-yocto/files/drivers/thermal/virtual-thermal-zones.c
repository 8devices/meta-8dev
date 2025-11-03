// SPDX-License-Identifier: GPL-2.0
/*
 * Generic Virtual Thermal Zones Driver
 *
 * based on:
 * - drivers/thermal/thermal_of.c (kernel 6.6) : Copyright (c) 2013 Eduardo Valentin <eduardo.valentin@ti.com>, Texas Instruments.
 * - drivers/thermal/qcom/qti_virtual_sensor.c (kernel 4.14) : Copyright (c) 2017-2019 The Linux Foundation.
 *
 * Copyright (c) 2025 8devices UAB
 * Copyright (c) 2025 Giedrė Šimkūnaitė <giedre.s@8devices.com>
 *
 * This driver registers virtual thermal zones from device tree nodes with
 * compatible = "virtual-thermal-zone". Virtual zones aggregate
 * temperatures from multiple source thermal zones using configurable calculation methods.
 */

#define pr_fmt(fmt) KBUILD_MODNAME ": " fmt

#include <linux/err.h>
#include <linux/init.h>
#include <linux/module.h>
#include <linux/mutex.h>
#include <linux/of.h>
#include <linux/platform_device.h>
#include <linux/slab.h>
#include <linux/sort.h>
#include <linux/thermal.h>

/**
 * enum temp_calc_logic - Temperature calculation method types
 */
enum temp_calc_logic {
	LOGIC_NONE = 0,
	LOGIC_MAX,
	LOGIC_MIN,
	LOGIC_AVERAGE,
	LOGIC_MEDIAN,
	LOGIC_MEAN,
	LOGIC_WEIGHTED_AVERAGE,
	LOGIC_ROLLING_AVERAGE,
	LOGIC_EXPONENTIAL_AVERAGE,
};

/* String names for temperature calculation methods */
static const char * const logic_names[] = {
	[LOGIC_NONE] = "none",
	[LOGIC_MAX] = "max",
	[LOGIC_MIN] = "min",
	[LOGIC_AVERAGE] = "average",
	[LOGIC_MEDIAN] = "median",
	[LOGIC_MEAN] = "mean",
	[LOGIC_WEIGHTED_AVERAGE] = "weighted-average",
	[LOGIC_ROLLING_AVERAGE] = "rolling-average",
	[LOGIC_EXPONENTIAL_AVERAGE] = "exponential-average",
};

#define MAX_VIRTUAL_ZONES 32
#define ROLLING_AVG_WINDOW_SIZE 5

/**
 * struct virt_tz - Runtime data for virtual thermal zone
 * @tz: Array of source thermal zone device pointers
 * @num_sensors: Number of source thermal zones
 * @logic: Temperature calculation method
 * @lock: Mutex for protecting concurrent access
 * @of_node: Cached device tree node pointer
 * @rolling_temps: Circular buffer for rolling average
 * @rolling_index: Current index in rolling buffer
 * @rolling_count: Number of valid entries in rolling buffer
 * @exp_avg_temp: Last exponential average temperature
 * @exp_avg_initialized: Whether exponential average is initialized
 */
struct virt_tz {
	struct thermal_zone_device **tz;
	int num_sensors;
	enum temp_calc_logic logic;
	struct mutex lock;
	struct device_node *of_node;
	/* Rolling average state */
	int rolling_temps[ROLLING_AVG_WINDOW_SIZE];
	int rolling_index;
	int rolling_count;
	/* Exponential average state */
	int exp_avg_temp;
	bool exp_avg_initialized;
};

/**
 * struct zone_defer_entry - Track defer count for each zone
 * @name: Allocated copy of zone name from device tree
 * @defer_count: Number of times this zone caused a defer
 * @permanent_fail: True if zone has permanent error (invalid sources)
 */
struct zone_defer_entry {
	char *name;
	int defer_count;
	bool permanent_fail;
};

#define MAX_DEFER_COUNT 2

/* Global defer tracking - persists across probe attempts
 * Note: These are static globals because kernel clears platform_drvdata on probe failure
 */
static struct zone_defer_entry global_defer_list[MAX_VIRTUAL_ZONES];
static int global_defer_list_count;

/* Global registered zones tracking - persists across probe attempts
 * Stores successfully registered zones so we don't re-register them on defer
 */
static struct thermal_zone_device *global_registered_zones[MAX_VIRTUAL_ZONES];
static int global_registered_count;

/**
 * cleanup_global_defer_list() - Clean up all allocated zone name strings in global defer list
 */
static void cleanup_global_defer_list(void)
{
	int i;

	for (i = 0; i < global_defer_list_count; i++) {
		kfree(global_defer_list[i].name);
		global_defer_list[i].name = NULL;
	}
	global_defer_list_count = 0;
}

/**
 * get_zone_defer_count() - Get defer count for a zone
 * @zone_name: Name of the zone to look up
 *
 * Return: defer count for the zone, or 0 if not found
 */
static int get_zone_defer_count(const char *zone_name)
{
	int i;

	if (!zone_name)
		return 0;

	for (i = 0; i < global_defer_list_count; i++) {
		if (!strcmp(global_defer_list[i].name, zone_name))
			return global_defer_list[i].defer_count;
	}

	return 0;
}

/**
 * increment_zone_defer_count() - Increment defer count for a zone
 * @zone_name: Name of the zone to increment
 */
static void increment_zone_defer_count(const char *zone_name)
{
	int i;
	char *name_copy;

	if (!zone_name)
		return;

	/* Check if zone already exists in list */
	for (i = 0; i < global_defer_list_count; i++) {
		if (!strcmp(global_defer_list[i].name, zone_name)) {
			global_defer_list[i].defer_count++;
			return;
		}
	}

	/* Add new entry if space available */
	if (global_defer_list_count < MAX_VIRTUAL_ZONES) {
		/* Allocate and copy zone name */
		name_copy = kstrdup(zone_name, GFP_KERNEL);
		if (!name_copy) {
			/* CRITICAL: Cannot track defer without memory - use BUG_ON to halt */
			pr_crit("CRITICAL: Failed to allocate memory for zone name '%s'\n", zone_name);
			BUG();
		}

		global_defer_list[global_defer_list_count].name = name_copy;
		global_defer_list[global_defer_list_count].defer_count = 1;
		global_defer_list[global_defer_list_count].permanent_fail = false;
		global_defer_list_count++;
	} else {
		pr_warn("defer_list full (%d entries), cannot track defer for zone '%s'\n", MAX_VIRTUAL_ZONES, zone_name);
	}
}

/**
 * mark_zone_permanent_fail() - Mark a zone as permanently failed
 * @zone_name: Name of the zone to mark
 */
static void mark_zone_permanent_fail(const char *zone_name)
{
	int i;
	char *name_copy;

	if (!zone_name)
		return;

	/* Check if zone already exists in list */
	for (i = 0; i < global_defer_list_count; i++) {
		if (!strcmp(global_defer_list[i].name, zone_name)) {
			global_defer_list[i].permanent_fail = true;
			return;
		}
	}

	/* Add new entry if space available */
	if (global_defer_list_count < MAX_VIRTUAL_ZONES) {
		/* Allocate and copy zone name */
		name_copy = kstrdup(zone_name, GFP_KERNEL);
		if (!name_copy) {
			/* CRITICAL: Cannot track permanent fail without memory - use BUG_ON to halt */
			pr_crit("CRITICAL: Failed to allocate memory for zone name '%s'\n", zone_name);
			BUG();
		}

		global_defer_list[global_defer_list_count].name = name_copy;
		global_defer_list[global_defer_list_count].defer_count = 0;
		global_defer_list[global_defer_list_count].permanent_fail = true;
		global_defer_list_count++;
	} else {
		pr_warn("defer_list full (%d entries), cannot track permanent fail for zone '%s'\n", MAX_VIRTUAL_ZONES, zone_name);
	}
}

/**
 * is_zone_permanent_fail() - Check if a zone is marked as permanently failed
 * @zone_name: Name of the zone to check
 *
 * Return: true if zone is permanently failed, false otherwise
 */
static bool is_zone_permanent_fail(const char *zone_name)
{
	int i;

	if (!zone_name)
		return false;

	for (i = 0; i < global_defer_list_count; i++) {
		if (!strcmp(global_defer_list[i].name, zone_name))
			return global_defer_list[i].permanent_fail;
	}

	return false;
}

/**
 * has_deferred_zones() - Check if there are zones that might still be deferred
 *
 * Return: true if there are zones with defer count > 0 and not permanently failed
 */
static bool has_deferred_zones(void)
{
	int i;

	for (i = 0; i < global_defer_list_count; i++) {
		/* If zone has defer attempts and is not permanently failed,
		 * it might be deferred again in future probe attempts
		 */
		if (global_defer_list[i].defer_count > 0 &&
		    !global_defer_list[i].permanent_fail)
			return true;
	}

	return false;
}

/**
 * zone_permanent_fail_count() - Count zones marked as permanently failed
 *
 * Return: Number of zones marked with permanent_fail = true
 */
static int zone_permanent_fail_count(void)
{
	int i, count = 0;

	for (i = 0; i < global_defer_list_count; i++) {
		if (global_defer_list[i].permanent_fail)
			count++;
	}

	return count;
}

/**
 * is_zone_already_registered() - Check if a zone is already registered
 * @zone_name: Name of the zone to check
 *
 * Return: true if zone is already registered, false otherwise
 */
static bool is_zone_already_registered(const char *zone_name)
{
	int i;

	if (!zone_name)
		return false;

	for (i = 0; i < global_registered_count; i++) {
		if (global_registered_zones[i] &&
		    global_registered_zones[i]->type &&
		    !strcmp(global_registered_zones[i]->type, zone_name))
			return true;
	}

	return false;
}

/**
 * compare_ints() - Comparison function for sorting
 */
static int compare_ints(const void *a, const void *b)
{
	int val_a = *(int *)a;
	int val_b = *(int *)b;

	if (val_a < val_b)
		return -1;
	if (val_a > val_b)
		return 1;
	return 0;
}

/**
 * calculate_max_temp() - Calculate maximum temperature
 */
static int calculate_max_temp(int *temps, int count)
{
	int max_temp = INT_MIN;
	int i;

	for (i = 0; i < count; i++) {
		if (temps[i] > max_temp)
			max_temp = temps[i];
	}

	return max_temp;
}

/**
 * calculate_min_temp() - Calculate minimum temperature
 */
static int calculate_min_temp(int *temps, int count)
{
	int min_temp = INT_MAX;
	int i;

	for (i = 0; i < count; i++) {
		if (temps[i] < min_temp)
			min_temp = temps[i];
	}

	return min_temp;
}

/**
 * calculate_average_temp() - Calculate average temperature
 */
static int calculate_average_temp(int *temps, int count)
{
	long long sum = 0;
	int i;

	for (i = 0; i < count; i++)
		sum += temps[i];

	return (int)(sum / count);
}

/**
 * calculate_mean_temp() - Calculate mean temperature (same as average)
 */
static int calculate_mean_temp(int *temps, int count)
{
	return calculate_average_temp(temps, count);
}

/**
 * calculate_median_temp() - Calculate median temperature
 */
static int calculate_median_temp(int *temps, int count)
{
	int *sorted_temps;
	int median;

	sorted_temps = kmemdup(temps, count * sizeof(int), GFP_KERNEL);
	if (!sorted_temps)
		return calculate_average_temp(temps, count);

	sort(sorted_temps, count, sizeof(int), compare_ints, NULL);

	if (count % 2 == 0)
		median = (int)(((long long)sorted_temps[count / 2 - 1] + sorted_temps[count / 2]) / 2);
	else
		median = sorted_temps[count / 2];

	kfree(sorted_temps);
	return median;
}

/**
 * calculate_weighted_average_temp() - Calculate weighted average
 * Weights are equal for now (same as average)
 */
static int calculate_weighted_average_temp(int *temps, int count)
{
	/* For now, equal weights = simple average */
	return calculate_average_temp(temps, count);
}

/**
 * calculate_rolling_average_temp() - Calculate rolling average
 * @virt: Virtual thermal zone structure
 * @current_temp: Current aggregated temperature
 *
 * Maintains a circular buffer and returns the average of the window
 */
static int calculate_rolling_average_temp(struct virt_tz *virt, int current_temp)
{
	long long sum = 0;
	int i;

	/* Add current temp to circular buffer */
	virt->rolling_temps[virt->rolling_index] = current_temp;
	virt->rolling_index = (virt->rolling_index + 1) % ROLLING_AVG_WINDOW_SIZE;

	if (virt->rolling_count < ROLLING_AVG_WINDOW_SIZE)
		virt->rolling_count++;

	/* Calculate average of valid entries */
	for (i = 0; i < virt->rolling_count; i++)
		sum += virt->rolling_temps[i];

	return (int)(sum / virt->rolling_count);
}

/**
 * calculate_exponential_average_temp() - Calculate exponential moving average
 * @virt: Virtual thermal zone structure
 * @current_temp: Current aggregated temperature
 *
 * Uses alpha = 0.3 for smoothing factor
 * EMA = alpha * current + (1 - alpha) * previous
 */
static int calculate_exponential_average_temp(struct virt_tz *virt, int current_temp)
{
	int ema;

	if (!virt->exp_avg_initialized) {
		virt->exp_avg_temp = current_temp;
		virt->exp_avg_initialized = true;
		return current_temp;
	}

	/* Alpha = 0.3, so: EMA = (3 * current + 7 * previous) / 10 */
	ema = (int)(((long long)3 * current_temp + (long long)7 * virt->exp_avg_temp) / 10);
	virt->exp_avg_temp = ema;

	return ema;
}

/**
 * enum tz_type - Thermal zone type in device tree
 */
enum tz_type {
	TZ_NOT_IN_DTS = 0,
	TZ_IS_REAL,
	TZ_IS_VIRTUAL,
};

/**
 * of_find_thermal_zone_by_name() - Check thermal zone type in device tree
 * @name: thermal zone name to search for
 *
 * Return: TZ_NOT_IN_DTS if zone not found in DT,
 *         TZ_IS_VIRTUAL if zone is virtual thermal zone,
 *         TZ_IS_REAL if zone is a real/physical thermal zone
 */
static enum tz_type of_find_thermal_zone_by_name(const char *name)
{
	struct device_node *tz_np, *np;
	enum tz_type type = TZ_NOT_IN_DTS;

	if (!name)
		return TZ_NOT_IN_DTS;

	tz_np = of_find_node_by_name(NULL, "thermal-zones");
	if (!tz_np)
		return TZ_NOT_IN_DTS;

	np = of_get_child_by_name(tz_np, name);
	if (np) {
		if (of_device_is_compatible(np, "virtual-thermal-zone"))
			type = TZ_IS_VIRTUAL;
		else
			type = TZ_IS_REAL;
		of_node_put(np);
	}

	of_node_put(tz_np);
	return type;
}

/**
 * of_find_trip_id() - Find trip ID by device tree node
 * @np: device node of thermal zone
 * @trip: device node of trip point
 *
 * Return: trip index or negative error code
 */
static int of_find_trip_id(struct device_node *np, struct device_node *trip)
{
	struct device_node *trips;
	struct device_node *t;
	int i = 0;

	trips = of_get_child_by_name(np, "trips");
	if (!trips) {
		pr_err("Failed to find 'trips' node\n");
		return -EINVAL;
	}

	for_each_child_of_node(trips, t) {
		if (t == trip) {
			of_node_put(t);
			goto out;
		}
		i++;
	}

	i = -ENXIO;
out:
	of_node_put(trips);
	return i;
}

/**
 * virt_tz_read_temp() - Read aggregated temperature
 * @tz: Virtual thermal zone device
 * @temp: Output temperature in millidegree Celsius
 *
 * Reads temperature from all source thermal zones and calculates
 * the result based on configured calculation method (max, min, average, etc.)
 *
 * Thread-safe: Uses mutex to protect concurrent access
 *
 * Return: 0 on success, negative error code on failure
 */
static int virt_tz_read_temp(struct thermal_zone_device *tz, int *temp)
{
	struct virt_tz *virt;
	int *temps;
	int sens_temp, ret;
	int i, valid_count = 0;
	int calculated_temp;

	if (!tz || !temp)
		return -EINVAL;

	virt = tz->devdata;
	if (!virt)
		return -EINVAL;

	if (!virt->tz)
		return -EINVAL;

	/* Allocate temporary array for temperature readings */
	temps = kcalloc(virt->num_sensors, sizeof(int), GFP_KERNEL);
	if (!temps)
		return -ENOMEM;

	/* Read temperatures from all source zones */
	for (i = 0; i < virt->num_sensors; i++) {
		if (!virt->tz[i])
			continue;

		ret = thermal_zone_get_temp(virt->tz[i], &sens_temp);
		if (ret) {
			pr_debug("Virtual zone '%s': failed to read sensor %d: %d\n",
				 tz->type, i, ret);
			continue;
		}

		temps[valid_count++] = sens_temp;
	}

	if (valid_count == 0) {
		pr_err("Virtual zone '%s': no valid temperature readings\n", tz->type);
		kfree(temps);
		return -ENODATA;
	}

	/* Lock for concurrent access protection (rolling/exponential avg state) */
	mutex_lock(&virt->lock);

	/* Calculate temperature based on configured calculation method */
	switch (virt->logic) {
	case LOGIC_NONE:
		/* No calculation needed, just pass through the single source temperature */
		calculated_temp = temps[0];
		break;
	case LOGIC_MAX:
		calculated_temp = calculate_max_temp(temps, valid_count);
		break;
	case LOGIC_MIN:
		calculated_temp = calculate_min_temp(temps, valid_count);
		break;
	case LOGIC_AVERAGE:
		calculated_temp = calculate_average_temp(temps, valid_count);
		break;
	case LOGIC_MEDIAN:
		calculated_temp = calculate_median_temp(temps, valid_count);
		break;
	case LOGIC_MEAN:
		calculated_temp = calculate_mean_temp(temps, valid_count);
		break;
	case LOGIC_WEIGHTED_AVERAGE:
		calculated_temp = calculate_weighted_average_temp(temps, valid_count);
		break;
	case LOGIC_ROLLING_AVERAGE:
		/* For rolling average, first get current aggregate (use average) */
		calculated_temp = calculate_average_temp(temps, valid_count);
		/* Then apply rolling average filter */
		calculated_temp = calculate_rolling_average_temp(virt, calculated_temp);
		break;
	case LOGIC_EXPONENTIAL_AVERAGE:
		/* For exponential average, first get current aggregate (use average) */
		calculated_temp = calculate_average_temp(temps, valid_count);
		/* Then apply exponential smoothing filter */
		calculated_temp = calculate_exponential_average_temp(virt, calculated_temp);
		break;
	default:
		calculated_temp = calculate_max_temp(temps, valid_count);
		break;
	}

	mutex_unlock(&virt->lock);

	kfree(temps);
	*temp = calculated_temp;
	return 0;
}

/**
 * __virt_tz_bind() - Bind cooling device to a trip
 */
static int __virt_tz_bind(struct device_node *map_np, int index, int trip_id,
			       struct thermal_zone_device *tz,
			       struct thermal_cooling_device *cdev)
{
	struct of_phandle_args cooling_spec;
	int ret, weight = THERMAL_WEIGHT_DEFAULT;

	of_property_read_u32(map_np, "contribution", &weight);

	ret = of_parse_phandle_with_args(map_np, "cooling-device",
					  "#cooling-cells", index, &cooling_spec);
	if (ret < 0) {
		pr_err("Invalid cooling-device entry\n");
		return ret;
	}

	if (!cooling_spec.np) {
		pr_err("NULL cooling device node pointer\n");
		return -EINVAL;
	}

	of_node_put(cooling_spec.np);

	if (cooling_spec.args_count < 2) {
		pr_err("Wrong reference to cooling device, missing limits\n");
		return -EINVAL;
	}

	if (cooling_spec.np != cdev->np)
		return 0;

	ret = thermal_zone_bind_cooling_device(tz, trip_id, cdev,
					       cooling_spec.args[1],
					       cooling_spec.args[0],
					       weight);
	if (ret)
		pr_err("Failed to bind '%s' with '%s': %d\n",
		       tz->type, cdev->type, ret);

	return ret;
}

/**
 * __virt_tz_unbind() - Unbind cooling device from a trip
 */
static int __virt_tz_unbind(struct device_node *map_np, int index, int trip_id,
				 struct thermal_zone_device *tz,
				 struct thermal_cooling_device *cdev)
{
	struct of_phandle_args cooling_spec;
	int ret;

	ret = of_parse_phandle_with_args(map_np, "cooling-device",
					  "#cooling-cells", index, &cooling_spec);
	if (ret < 0) {
		pr_err("Invalid cooling-device entry\n");
		return ret;
	}

	if (!cooling_spec.np) {
		pr_err("NULL cooling device node pointer\n");
		return -EINVAL;
	}

	of_node_put(cooling_spec.np);

	if (cooling_spec.args_count < 2) {
		pr_err("Wrong reference to cooling device, missing limits\n");
		return -EINVAL;
	}

	if (cooling_spec.np != cdev->np)
		return 0;

	ret = thermal_zone_unbind_cooling_device(tz, trip_id, cdev);
	if (ret)
		pr_err("Failed to unbind '%s' with '%s': %d\n",
		       tz->type, cdev->type, ret);

	return ret;
}

/**
 * virt_tz_for_each_cooling_device() - Process each cooling device in a map
 */
static int virt_tz_for_each_cooling_device(struct device_node *tz_np,
						 struct device_node *map_np,
						 struct thermal_zone_device *tz,
						 struct thermal_cooling_device *cdev,
						 int is_bind)
{
	struct device_node *tr_np;
	int count, i, trip_id, ret;

	if (!tz_np || !map_np || !tz || !cdev)
		return -EINVAL;

	tr_np = of_parse_phandle(map_np, "trip", 0);
	if (!tr_np)
		return -ENODEV;

	trip_id = of_find_trip_id(tz_np, tr_np);
	of_node_put(tr_np);
	if (trip_id < 0)
		return trip_id;

	count = of_count_phandle_with_args(map_np, "cooling-device", "#cooling-cells");
	if (count <= 0) {
		pr_err("Add a cooling_device property with at least one device\n");
		return -ENOENT;
	}

	for (i = 0; i < count; i++) {
		if (is_bind)
			ret = __virt_tz_bind(map_np, i, trip_id, tz, cdev);
		else
			ret = __virt_tz_unbind(map_np, i, trip_id, tz, cdev);

		if (ret)
			return ret;
	}

	return 0;
}

/**
 * virt_tz_for_each_cooling_maps() - Iterate through all cooling maps
 */
static int virt_tz_for_each_cooling_maps(struct device_node *tz_np,
					       struct thermal_zone_device *tz,
					       struct thermal_cooling_device *cdev,
					       int is_bind)
{
	struct device_node *cm_np, *child;
	int ret = 0;

	if (!tz_np || !tz || !cdev)
		return -EINVAL;

	cm_np = of_get_child_by_name(tz_np, "cooling-maps");
	if (!cm_np)
		return 0; /* No cooling maps is not an error */

	for_each_child_of_node(cm_np, child) {
		ret = virt_tz_for_each_cooling_device(tz_np, child, tz, cdev, is_bind);
		if (ret) {
			of_node_put(child);
			break;
		}
	}

	of_node_put(cm_np);
	return ret;
}

/**
 * virt_tz_bind() - Bind cooling device to virtual thermal zone
 */
static int virt_tz_bind(struct thermal_zone_device *tz,
			      struct thermal_cooling_device *cdev)
{
	struct virt_tz *virt = tz->devdata;
	struct device_node *tz_np;

	if (!virt || !virt->of_node)
		return -ENODEV;

	tz_np = virt->of_node;

	return virt_tz_for_each_cooling_maps(tz_np, tz, cdev, 1);
}

/**
 * virt_tz_unbind() - Unbind cooling device from virtual thermal zone
 */
static int virt_tz_unbind(struct thermal_zone_device *tz,
			        struct thermal_cooling_device *cdev)
{
	struct virt_tz *virt = tz->devdata;
	struct device_node *tz_np;

	if (!virt || !virt->of_node)
		return -ENODEV;

	tz_np = virt->of_node;

	return virt_tz_for_each_cooling_maps(tz_np, tz, cdev, 0);
}

static struct thermal_zone_device_ops virt_tz_ops = {
	.get_temp = virt_tz_read_temp,
	.bind = virt_tz_bind,
	.unbind = virt_tz_unbind,
};

/**
 * virt_tz_parse_trips() - Parse trip points from DT
 */
static struct thermal_trip *virt_tz_parse_trips(struct device_node *np, int *ntrips)
{
	struct thermal_trip *trips;
	struct device_node *trips_node, *trip;
	int count, i = 0, ret;
	u32 temp, hyst;
	const char *type_str;

	if (!ntrips)
		return ERR_PTR(-EINVAL);

	*ntrips = 0;

	trips_node = of_get_child_by_name(np, "trips");
	if (!trips_node)
		return NULL;

	count = of_get_child_count(trips_node);
	if (!count) {
		of_node_put(trips_node);
		return NULL;
	}

	trips = kzalloc(sizeof(*trips) * count, GFP_KERNEL);
	if (!trips) {
		of_node_put(trips_node);
		return ERR_PTR(-ENOMEM);
	}

	for_each_child_of_node(trips_node, trip) {
		ret = of_property_read_u32(trip, "temperature", &temp);
		if (ret) {
			pr_err("Trip %s: missing temperature\n", trip->name);
			goto err_free;
		}

		ret = of_property_read_u32(trip, "hysteresis", &hyst);
		if (ret) {
			pr_err("Trip %s: missing hysteresis\n", trip->name);
			goto err_free;
		}

		ret = of_property_read_string(trip, "type", &type_str);
		if (ret) {
			pr_err("Trip %s: missing type\n", trip->name);
			goto err_free;
		}

		trips[i].temperature = temp;
		trips[i].hysteresis = hyst;

		if (!strcmp(type_str, "active"))
			trips[i].type = THERMAL_TRIP_ACTIVE;
		else if (!strcmp(type_str, "passive"))
			trips[i].type = THERMAL_TRIP_PASSIVE;
		else if (!strcmp(type_str, "hot"))
			trips[i].type = THERMAL_TRIP_HOT;
		else if (!strcmp(type_str, "critical"))
			trips[i].type = THERMAL_TRIP_CRITICAL;
		else {
			pr_err("Trip %s: invalid type '%s'\n", trip->name, type_str);
			goto err_free;
		}

		i++;
	}

	of_node_put(trips_node);
	*ntrips = count;
	return trips;

err_free:
	of_node_put(trip);
	of_node_put(trips_node);
	kfree(trips);
	return ERR_PTR(-EINVAL);
}

/**
 * virt_tz_parse_params() - Parse thermal zone parameters from DT
 * @np: Device tree node
 * @tzp: Thermal zone params structure to fill
 *
 * Parses optional thermal zone parameters like sustainable-power,
 * coefficients (slope/offset), thermal-governor, etc.
 */
static void virt_tz_parse_params(struct device_node *np,
				      struct thermal_zone_params *tzp)
{
	const char *governor_name;
	int coef[2];
	int ncoef = ARRAY_SIZE(coef);
	u32 prop;
	int ret;

	/* Valid governor names from kernel 6.6 */
	static const char * const valid_governors[] = {
		"step_wise",
		"fair_share",
		"bang_bang",
		"user_space",
		"power_allocator",
		NULL
	};

	if (!tzp)
		return;

	tzp->no_hwmon = true;

	/* Parse thermal governor */
	ret = of_property_read_string(np, "thermal-governor", &governor_name);
	if (!ret) {
		int i;
		bool valid = false;

		/* Validate governor name against known governors */
		for (i = 0; valid_governors[i] != NULL; i++) {
			if (!strcmp(governor_name, valid_governors[i])) {
				valid = true;
				break;
			}
		}

		if (valid) {
			strscpy(tzp->governor_name, governor_name, THERMAL_NAME_LENGTH);
			pr_debug("%pOFn: Using thermal governor '%s'\n", np, governor_name);
		} else {
			pr_warn("%pOFn: Unknown thermal governor '%s', using default\n",
				np, governor_name);
		}
	}

	if (!of_property_read_u32(np, "sustainable-power", &prop))
		tzp->sustainable_power = prop;

	/*
	 * For now, the thermal framework supports only one sensor per
	 * thermal zone. Thus, we are considering only the first two
	 * values as slope and offset.
	 */
	ret = of_property_read_u32_array(np, "coefficients", coef, ncoef);
	if (ret) {
		coef[0] = 1;
		coef[1] = 0;
	}

	tzp->slope = coef[0];
	tzp->offset = coef[1];
}

/**
 * virt_tz_unregister() - Unregister and cleanup a virtual thermal zone
 * @tz: Thermal zone device to unregister
 *
 * This function properly releases all allocated resources in the correct order:
 * 1. Disable the thermal zone (stops polling)
 * 2. Unregister from thermal subsystem
 * 3. Free allocated memory (trips, virt structure)
 */
static void virt_tz_unregister(struct thermal_zone_device *tz)
{
	struct virt_tz *virt;
	struct thermal_trip *trips;

	if (!tz)
		return;

	/* Save pointers before unregistering */
	virt = tz->devdata;
	trips = tz->trips;

	/* Step 1: Disable thermal zone (stops monitoring/polling) */
	thermal_zone_device_disable(tz);

	/* Step 2: Unregister from thermal subsystem
	 * This will:
	 * - Remove from thermal zone list
	 * - Unbind all cooling devices
	 * - Cancel polling work
	 * - Remove governor
	 * - Remove hwmon sysfs
	 * - Free IDA resources
	 * - Delete device
	 * - Free tzp and tz structures
	 */
	thermal_zone_device_unregister(tz);

	/* Step 3: Free our allocated resources
	 * Note: tz pointer is now invalid after unregister
	 */
	kfree(trips);

	if (virt) {
		kfree(virt->tz);
		of_node_put(virt->of_node);
		mutex_destroy(&virt->lock);
		kfree(virt);
	}
}

/**
 * virt_tz_register() - Register a virtual thermal zone from DT
 * @np: Device tree node of the virtual thermal zone
 *
 * Device tree example:
 *   cpuss-max-step {
 *       compatible = "virtual-thermal-zone";
 *       source-thermal-zones = "cluster-thermal", "cpu0-thermal",
 *                              "cpu1-thermal", "cpu2-thermal";
 *       polling-delay-passive = <100>;
 *       polling-delay = <1000>;
 *       sustainable-power = <1000>;
 *       coefficients = <1 0>;
 *
 *       trips {
 *           cpuss_passive: cpuss-passive {
 *               temperature = <75000>;
 *               hysteresis = <5000>;
 *               type = "passive";
 *           };
 *       };
 *
 *       cooling-maps {
 *           map0 {
 *               trip = <&cpuss_passive>;
 *               cooling-device = <&CPU0 THERMAL_NO_LIMIT THERMAL_NO_LIMIT>;
 *           };
 *       };
 *   };
 *
 * Return: thermal zone device pointer on success, ERR_PTR on error
 */
static struct thermal_zone_device *virt_tz_register(struct device_node *np)
{
	struct thermal_zone_device *tz;
	struct virt_tz *virt;
	struct thermal_trip *trips;
	struct thermal_zone_params tzp = {};
	const char *source_name;
	char *source_name_stable;
	u32 polling_delay = 0, passive_delay = 0;
	int ntrips, mask;
	int count, i, ret;
	bool defer = false;
	int virtual_count = 0, notfound_count = 0;
	char *virtual_zones[MAX_VIRTUAL_ZONES] = {NULL};
	char *notfound_zones[MAX_VIRTUAL_ZONES] = {NULL};
	enum tz_type tz_type;
	
	/* Read source thermal zones */
	count = of_property_count_strings(np, "source-thermal-zones");
	if (count <= 0) {
		pr_err("%pOFn: missing or invalid source-thermal-zones property\n", np);
		ret = -EINVAL;
		goto no_free_mark;
	}

	/* Allocate virtual zone structure */
	virt = kzalloc(sizeof(*virt), GFP_KERNEL);
	if (!virt) {
		pr_err("%pOFn: failed to allocate memory for virtual zone structure\n", np);
		ret = -ENOMEM;
		goto no_free_mark;
	}

	virt->num_sensors = count;
	mutex_init(&virt->lock);
	virt->of_node = of_node_get(np);

	/* Parse calculate property from DT */
	if (count == 1) {
		/* Single source: always use LOGIC_NONE - ignore DT calculate property */
		virt->logic = LOGIC_NONE;
	} else {
		/* Multiple sources: parse calculate from DT, default to LOGIC_MAX */
		const char *calculate_str;

		virt->logic = LOGIC_MAX;  /* Default to max */

		if (!of_property_read_string(np, "calculate", &calculate_str)) {
			if (!strcmp(calculate_str, "max"))
				virt->logic = LOGIC_MAX;
			else if (!strcmp(calculate_str, "min"))
				virt->logic = LOGIC_MIN;
			else if (!strcmp(calculate_str, "average"))
				virt->logic = LOGIC_AVERAGE;
			else if (!strcmp(calculate_str, "median"))
				virt->logic = LOGIC_MEDIAN;
			else if (!strcmp(calculate_str, "mean"))
				virt->logic = LOGIC_MEAN;
			else if (!strcmp(calculate_str, "weighted-average"))
				virt->logic = LOGIC_WEIGHTED_AVERAGE;
			else if (!strcmp(calculate_str, "rolling-average"))
				virt->logic = LOGIC_ROLLING_AVERAGE;
			else if (!strcmp(calculate_str, "exponential-average"))
				virt->logic = LOGIC_EXPONENTIAL_AVERAGE;
			else
				pr_warn("%pOFn: unknown calculate method '%s', using 'max'\n",
					np, calculate_str);
		}
	}

	virt->tz = kcalloc(count, sizeof(*virt->tz), GFP_KERNEL);
	if (!virt->tz) {
		ret = -ENOMEM;
		goto free_virt;
	}

	/* Look up and validate source thermal zones */
	for (i = 0; i < count; i++) {
		ret = of_property_read_string_index(np, "source-thermal-zones",
						     i, &source_name);
		if (ret) {
			pr_err("%pOFn: failed to read source zone %d\n", np, i);
			goto free_tz_array;
		}

		/* Copy source_name immediately to stable memory before any operations */
		source_name_stable = kstrdup(source_name, GFP_KERNEL);
		if (!source_name_stable) {
			pr_err("%pOFn: failed to allocate memory for source zone name\n", np);
			ret = -ENOMEM;
			goto free_tz_array;
		}

		virt->tz[i] = thermal_zone_get_zone_by_name(source_name_stable);
		if (IS_ERR(virt->tz[i])) {
			tz_type = of_find_thermal_zone_by_name(source_name_stable);

			if (tz_type == TZ_IS_VIRTUAL) {
				/* Virtual zones cannot use other virtual zones as sources */
				if (virtual_count < MAX_VIRTUAL_ZONES) {
					/* Reuse the stable copy we already made */
					virtual_zones[virtual_count] = source_name_stable;
					virtual_count++;
					source_name_stable = NULL;  /* Prevent double-free */
				} else if (virtual_count == MAX_VIRTUAL_ZONES) {
					pr_warn("%pOFn: too many virtual zone errors (>%d), some not reported\n", np, MAX_VIRTUAL_ZONES);
					virtual_count++;  /* Increment to avoid repeated warning */
				}
			} else if (tz_type == TZ_IS_REAL) {
				/* Real zone defined in DT but not registered yet - defer */
				pr_warn("%pOFn: source zone '%s' is not registered\n", np, source_name_stable);
				defer = true;
			} else {
				/* Zone not in DT - permanent configuration error */
				if (notfound_count < MAX_VIRTUAL_ZONES) {
					/* Reuse the stable copy we already made */
					notfound_zones[notfound_count] = source_name_stable;
					notfound_count++;
					source_name_stable = NULL;  /* Prevent double-free */
				} else if (notfound_count == MAX_VIRTUAL_ZONES) {
					pr_warn("%pOFn: too many notfound zone errors (>%d), some not reported\n", np, MAX_VIRTUAL_ZONES);
					notfound_count++;  /* Increment to avoid repeated warning */
				}
			}

			/* Free source_name_stable if we didn't store it in arrays */
			if (source_name_stable)
				kfree(source_name_stable);

			virt->tz[i] = NULL;  /* Clear ERR_PTR to prevent later issues */
			continue;
		}

		/* Zone found successfully, free the stable copy */
		kfree(source_name_stable);
	}

	/* Report all errors after validation */
	if (virtual_count || notfound_count) {
		if (virtual_count) {
			pr_err("%pOFn: virtual zones cannot be used as sources: ", np);
			for (i = 0; (i < virtual_count) && (i < MAX_VIRTUAL_ZONES); i++)
				pr_cont("%s%s", i ? ", " : "", virtual_zones[i]);
			if (virtual_count > MAX_VIRTUAL_ZONES)
				pr_cont(" (and %d more)", virtual_count - MAX_VIRTUAL_ZONES);
			pr_cont("\n");
		}

		if (notfound_count) {
			pr_err("%pOFn: source zones not found in device tree: ", np);
			for (i = 0; (i < notfound_count) && (i < MAX_VIRTUAL_ZONES); i++)
				pr_cont("%s%s", i ? ", " : "", notfound_zones[i]);
			if (notfound_count > MAX_VIRTUAL_ZONES)
				pr_cont(" (and %d more)", notfound_count - MAX_VIRTUAL_ZONES);
			pr_cont("\n");
		}

		ret = -EINVAL;
		goto free_tz_array;
	} else if (defer) {
		/* At least one source zone not registered yet - defer */
		ret = -EPROBE_DEFER;
		goto free_tz_array;
	}

	/* Parse trip points */
	trips = virt_tz_parse_trips(np, &ntrips);
	if (IS_ERR(trips)) {
		ret = PTR_ERR(trips);
		pr_err("%pOFn: failed to parse trip points: %d\n", np, ret);
		goto free_tz_array;
	}

	/* Validate trip count (GENMASK_ULL supports max 64 bits) */
	if (ntrips > 64) {
		pr_err("%pOFn: too many trip points (%d), maximum is 64\n", np, ntrips);
		ret = -EINVAL;
		kfree(trips);
		goto free_tz_array;
	}

	/* Read polling delays, set defaults if not specified */
	if (of_property_read_u32(np, "polling-delay-passive", &passive_delay))
		passive_delay = 100;  /* Default: 100ms */

	if (of_property_read_u32(np, "polling-delay", &polling_delay))
		polling_delay = 1000;  /* Default: 1000ms */

	/* Parse thermal zone parameters (slope, offset, sustainable-power, etc.) */
	virt_tz_parse_params(np, &tzp);

	mask = ntrips ? GENMASK_ULL(ntrips - 1, 0) : 0;

	/* Register thermal zone */
	tz = thermal_zone_device_register_with_trips(np->name, trips, ntrips,
						     mask, virt, &virt_tz_ops,
						     &tzp, passive_delay, polling_delay);
	if (IS_ERR(tz)) {
		ret = PTR_ERR(tz);
		pr_err("%pOFn: failed to register virtual thermal zone: %d\n", np, ret);
		goto free_trips;
	}

	/* Enable thermal zone */
	ret = thermal_zone_device_enable(tz);
	if (ret) {
		pr_err("%pOFn: failed to enable thermal zone: %d\n", np, ret);
		virt_tz_unregister(tz);
		goto no_free_mark;
	}

	/* Verify governor assignment */
	if (!tz->governor) {
		if (tzp.governor_name[0] != '\0') {
			pr_err("%pOFn: requested governor '%s' is not available\n", np, tzp.governor_name);
		} else {
			pr_err("%pOFn: default governor is not available\n", np);
		}
		virt_tz_unregister(tz);
		ret = -EINVAL;
		goto no_free_mark;
	}

	return tz;

free_trips:
	kfree(trips);
free_tz_array:
	kfree(virt->tz);
free_virt:
	of_node_put(virt->of_node);
	mutex_destroy(&virt->lock);
	kfree(virt);

no_free_mark:
	/* Free copied zone name strings */
	for (i = 0; (i < virtual_count) && (i < MAX_VIRTUAL_ZONES); i++)
		kfree(virtual_zones[i]);
	for (i = 0; (i < notfound_count) && (i < MAX_VIRTUAL_ZONES); i++)
		kfree(notfound_zones[i]);

	/* Mark zone as permanently failed on any error except defer */
	if (ret != -EPROBE_DEFER)
		mark_zone_permanent_fail(np->name);
	return ERR_PTR(ret);
}

/**
 * virt_tz_probe() - Platform driver probe
 */
static int virt_tz_probe(struct platform_device *pdev)
{
	struct device_node *np, *child;
	struct thermal_zone_device *tz;
	int skipped;
	int i;
	bool need_defer = false;
	const char *defer_zone_name = NULL;

	np = of_find_node_by_name(NULL, "thermal-zones");
	if (!np) {
		dev_info(&pdev->dev, "No thermal-zones node found\n");
		return -ENODEV;
	}

	for_each_available_child_of_node(np, child) {
		if (!of_device_is_compatible(child, "virtual-thermal-zone"))
			continue;

		/* Skip zones that are permanently failed */
		if (is_zone_permanent_fail(child->name)) {
			continue;
		}

		/* Skip zones that are already successfully registered */
		if (is_zone_already_registered(child->name)) {
			dev_dbg(&pdev->dev, "%pOFn: already registered, skipping\n", child);
			continue;
		}

		tz = virt_tz_register(child);
		if (IS_ERR(tz)) {
			int err = PTR_ERR(tz);

			if (err == -EPROBE_DEFER) {
				/* Increment defer count */
				increment_zone_defer_count(child->name);

				/* Check if just exceeded limit */
				if (get_zone_defer_count(child->name) >= MAX_DEFER_COUNT) {
					/* Print warning only once and mark as permanent fail */
					dev_warn(&pdev->dev, "%pOFn: exceeded maximum defer attempts (%d), skipping registration due to missing dependencies\n",
						 child, MAX_DEFER_COUNT);
					mark_zone_permanent_fail(child->name);
					continue;
				}

				/* Still under limit - defer probe */
				defer_zone_name = child->name;
				need_defer = true;
				of_node_put(child);
				break;
			}
			continue;
		}

		/* Track successfully registered zone */
		if (global_registered_count < MAX_VIRTUAL_ZONES) {
			global_registered_zones[global_registered_count++] = tz;
		} else {
			/* Exceeded maximum tracked zones - unregister immediately */
			dev_err(&pdev->dev, "Exceeded maximum of %d virtual thermal zones, unregistering '%s'\n",
				MAX_VIRTUAL_ZONES,
				child->name);
			virt_tz_unregister(tz);
		}
	}

	of_node_put(np);

	/* Handle defer: keep successfully registered zones */
	if (need_defer)
		return -EPROBE_DEFER;

	/* Get count of permanently failed zones */
	skipped = zone_permanent_fail_count();

	/* Check for complete failure: no zones found at all */
	if (skipped == 0 && global_registered_count == 0) {
		dev_info(&pdev->dev, "No virtual thermal zones found\n");
		return -ENODEV;
	}

	/* Check if nothing registered */
	if (global_registered_count == 0) {
		dev_info(&pdev->dev, "No zones successfully registered (skipped: %d)\n", skipped);
		/* All zones are permanently failed, clean up everything */
		dev_info(&pdev->dev, "All zones permanently failed, cleaning up\n");
		cleanup_global_defer_list();
		return -ENODEV;
	}

	/* If we have at least some zones registered (from this or previous probes), consider it success */
	/* (No message needed for zones already registered from previous probes) */

	/* Print summary and details of all registered zones */
	dev_info(&pdev->dev, "Registered %d virtual thermal zone%s (%d skipped due to missing dependencies)\n",
		 global_registered_count, (global_registered_count != 1) ? "s" : "", skipped);

	/* Print details of each registered zone */
	for (i = 0; i < global_registered_count; i++) {
		struct thermal_zone_device *rtz = global_registered_zones[i];
		struct virt_tz *virt;
		int ntrips;

		if (!rtz)
			continue;

		virt = rtz->devdata;
		ntrips = rtz->num_trips;

		if (virt) {
			dev_info(&pdev->dev, "  '%s': %d sources, %d trips, calculate '%s', governor '%s'\n",
				 rtz->type,
				 virt->num_sensors,
				 ntrips,
				 logic_names[virt->logic],
				 rtz->governor->name);
		}
	}

	/* Successful probe with registered zones - check if we should clean up defer tracking */
	if (!has_deferred_zones()) {
		/* No zones are pending defer, clean up global defer tracking */
		dev_info(&pdev->dev, "All zones resolved, cleaning up defer tracking\n");
		cleanup_global_defer_list();
	}

	return 0;
}

static int virt_tz_remove(struct platform_device *pdev)
{
	int i;

	/* Unregister all thermal zones from global array */
	for (i = 0; i < global_registered_count; i++) {
		if (global_registered_zones[i]) {
			virt_tz_unregister(global_registered_zones[i]);
			global_registered_zones[i] = NULL;
		}
	}
	global_registered_count = 0;

	/* Clean up global defer list */
	cleanup_global_defer_list();

	return 0;
}

static struct platform_driver virt_tz_driver = {
	.probe = virt_tz_probe,
	.remove = virt_tz_remove,
	.driver = {
		.name = "virtual-thermal-zones",
	},
};

static struct platform_device *virt_tz_pdev;

static int __init virt_tz_init(void)
{
	int ret;

	/* Register the platform driver */
	ret = platform_driver_register(&virt_tz_driver);
	if (ret)
		return ret;

	/* Create and register platform device (no DTS compatible needed) */
	virt_tz_pdev = platform_device_register_simple("virtual-thermal-zones",
						       -1, NULL, 0);
	if (IS_ERR(virt_tz_pdev)) {
		platform_driver_unregister(&virt_tz_driver);
		return PTR_ERR(virt_tz_pdev);
	}

	return 0;
}
late_initcall(virt_tz_init);

static void __exit virt_tz_exit(void)
{
	platform_device_unregister(virt_tz_pdev);
	platform_driver_unregister(&virt_tz_driver);
}
module_exit(virt_tz_exit);

MODULE_AUTHOR("Giedrė Šimkūnaitė <giedre.s@8devices.com>");
MODULE_DESCRIPTION("Generic Virtual Thermal Zones Driver");
MODULE_LICENSE("GPL v2");

