#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <getopt.h>
#include <stdint.h>
#include <unistd.h>
#include <ctype.h>
#include <arpa/inet.h>
#include <string.h>

#include "crc.h"

#define EEPROM_FILE_PATH "/sys/bus/i2c/devices/0-0056/eeprom"
#define EEPROM_MAGIC	"TLVeppr"
#define EEPROM_VERSION	0x01

#define ARRAY_SIZE(x) (sizeof(x) / sizeof((x)[0]))
#define IS_EEPROM_MAC(x) (x >= EEPROM_ATTR_MAC_FIRST && x <= EEPROM_ATTR_MAC_LAST)

#define MAC_SIZE_RAW 6
#define MAC_SIZE_STRING 17

enum tlv_code {
	/* Product related attributes */
	EEPROM_ATTR_PRODUCT_ID = 1,		/* char*, "ProductXYZ" */
	EEPROM_ATTR_SERIAL_NO,              	/* char*, "" */

	/* PCB related attributes */
	EEPROM_ATTR_PCB_NAME = 16,         	/* char*, "FooBar" */
	EEPROM_ATTR_PCB_REVISION,           	/* char*, "0002" */
	EEPROM_ATTR_PCB_PRDATE,             	/* time_t, seconds */
	EEPROM_ATTR_PCB_PRLOCATION,         	/* char*, "Kaunas" */
	EEPROM_ATTR_PCB_SN,                	/* char*, "" */

	/* MAC infoformation */
	EEPROM_ATTR_MAC = 224,
	EEPROM_ATTR_MAC_FIRST = 224,
	EEPROM_ATTR_MAC_1 = 224,
	EEPROM_ATTR_MAC_2,
	EEPROM_ATTR_MAC_3,
	EEPROM_ATTR_MAC_4,
	EEPROM_ATTR_MAC_5,
	EEPROM_ATTR_MAC_6,
	EEPROM_ATTR_MAC_7,
	EEPROM_ATTR_MAC_8,
	EEPROM_ATTR_MAC_9,
	EEPROM_ATTR_MAC_10,
	EEPROM_ATTR_MAC_11,
	EEPROM_ATTR_MAC_12,
	EEPROM_ATTR_MAC_13,
	EEPROM_ATTR_MAC_14,
	EEPROM_ATTR_MAC_15,
	EEPROM_ATTR_MAC_16 = 239,
	EEPROM_ATTR_MAC_LAST = 239,

	/* Calibration data */
	EEPROM_ATTR_RADIO_CALIBRATION_DATA = 240,
	EEPROM_ATTR_XTAL_CALIBRATION_DATA,
};

struct tlv_code_desc {
	enum tlv_code m_code;
	char *m_name;
};

const struct tlv_code_desc tlv_code_list[] = {
	{ EEPROM_ATTR_PRODUCT_ID, "PRODUCT_ID" },
	{ EEPROM_ATTR_SERIAL_NO, "SERIAL_NO" },
	{ EEPROM_ATTR_PCB_NAME, "PCB_NAME" },
	{ EEPROM_ATTR_PCB_REVISION, "PCB_REVISION" },
	{ EEPROM_ATTR_PCB_PRDATE, "PCB_PROD_DATE" },
	{ EEPROM_ATTR_PCB_PRLOCATION, "PCB_PROD_LOCATION" },
	{ EEPROM_ATTR_PCB_SN, "PCB_SN" },
	{ EEPROM_ATTR_RADIO_CALIBRATION_DATA, "RADIO_CALIBRATION_DATA" },
	{ EEPROM_ATTR_XTAL_CALIBRATION_DATA, "XTAL_CALIBRATION_DATA" },
	{ EEPROM_ATTR_MAC, "GENERIC_MAC" },
};

/*
 * EEPROM structure:
 *
 *                 MAGIC          VERSION  LENGTH     CRC
 *        |---------------------|  |---| |---------| |----
 * 00000  54 4c 56 65 70 70 72 00  00 01 00 00 00 09 bd 96  |TLVeppr.........|
 *        CRC  TYPE LEN.        DATA
 *        ----||--||---||-----------------|
 * 00010  8b e1 01 00 06 66 6f 6f  62 61 72 00 00 00 00 00  |.....foobar.....|
 * ...
 *
 */

struct __attribute__ ((__packed__)) eeprom_header {
	char magic[8];
	uint16_t version;
	uint32_t totallen;
	uint32_t crc32;
};

struct __attribute__ ((__packed__)) tlv_field {
	uint8_t type;
	uint16_t length;
	uint8_t value[0];
};

struct eeprom_data {
	size_t size;
	unsigned char *data;
};

struct __attribute__ ((__packed__)) mac_data {
	uint8_t byte[6];
	uint8_t iface[0];
};

int is_valid_tlvinfo_header(struct eeprom_header *hdr)
{
	if (strcmp(hdr->magic, EEPROM_MAGIC))
		return -1;

	return 0;
}

int is_valid_tlv(struct tlv_field *tlv)
{
	return (tlv->type != 0x00) && (tlv->type != 0xff);
}

void print_value(char *value, size_t len)
{
	int i;

	for (i = 0; i < len; i++)
		putchar(value[i]);
}

int tlv_name2type(char* name)
{
	int i;

	for (i = 0; i < ARRAY_SIZE(tlv_code_list); i++) {
		if (strcmp(name, tlv_code_list[i].m_name) == 0 &&
		    !IS_EEPROM_MAC(tlv_code_list[i].m_code)) {
			return tlv_code_list[i].m_code;
		}
	}

	return -1;
}

int tlvinfo_find_tlv(struct eeprom_data *eeprom, char *key, int *eeprom_index)
{
	struct eeprom_header *eeprom_hdr = (struct eeprom_header *)eeprom->data;
	struct tlv_field *eeprom_tlv;
	int eeprom_end;
	struct mac_data *mac_payload;
	char *iface = NULL;
	size_t iface_len;
	int tcode;
	char *temp_iface;

	*eeprom_index = sizeof(struct eeprom_header);
	eeprom_end = sizeof(struct eeprom_header) + ntohl(eeprom_hdr->totallen);

	if (*eeprom_index == eeprom_end)
		return -1;

	if (strstr(key, "GENERIC_MAC_"))
		iface = strrchr(key, '_') + 1;

	tcode = tlv_name2type(key);
	if (tcode < 0 && !iface)
		return -1;

	while (*eeprom_index < eeprom_end) {
		eeprom_tlv = (struct tlv_field *)&eeprom->data[*eeprom_index];

		if (!is_valid_tlv(eeprom_tlv))
			return -1;

		if (eeprom_tlv->type == tcode && !iface)
			return 0; /* found */

		if (IS_EEPROM_MAC(eeprom_tlv->type) && iface) {
			mac_payload = (struct mac_data *)eeprom_tlv->value;
			iface_len = ntohs(eeprom_tlv->length) - MAC_SIZE_RAW;
			temp_iface = (char *)malloc(iface_len);
			memset(temp_iface, '\0', iface_len);
			memcpy(temp_iface, mac_payload->iface, iface_len);
			if (strcmp(temp_iface, iface) == 0) {
				free(temp_iface);
				return 0;
			}
		 	free(temp_iface);
		}

		*eeprom_index += sizeof(struct tlv_field) + ntohs(eeprom_tlv->length);
	}

	return -1;
}

void decode_tlv_value(struct tlv_field *tlv, char **value, size_t *len)
{
	if (IS_EEPROM_MAC(tlv->type)) {
		*len = MAC_SIZE_STRING + 1;
		*value = malloc(*len);
		sprintf(*value, "%02X:%02X:%02X:%02X:%02X:%02X",
			tlv->value[0], tlv->value[1], tlv->value[2],
			tlv->value[3], tlv->value[4], tlv->value[5]);
	} else {
		*len = ntohs(tlv->length);
		*value = malloc(*len);
		memcpy(*value, tlv->value, ntohs(tlv->length));
	}
}

void show_tlv_code_list(void)
{
	int i;

	printf("TLV Name\n");
	printf("=================\n");
	for (i = 0; i < ARRAY_SIZE(tlv_code_list); i++) {
		if (tlv_code_list[i].m_code == EEPROM_ATTR_MAC) {
			printf("%s_*\n", tlv_code_list[i].m_name);
			continue;
		}
		printf("%s\n", tlv_code_list[i].m_name);
	}
}

int tlv_type2name(struct tlv_field *tlv, char** name)
{
	int i;
	struct mac_data *mac_payload;
	int iface_len;
	const char *mac_slot_prefix = "GENERIC_MAC_";

	if (IS_EEPROM_MAC(tlv->type)) {
		mac_payload = (struct mac_data *)tlv->value;
		iface_len = ntohs(tlv->length) - MAC_SIZE_RAW + strlen(mac_slot_prefix) + 1;
		*name = malloc(iface_len);
		snprintf(*name, iface_len, "%s%s", mac_slot_prefix, mac_payload->iface);
		return 0;
	}

	for (i = 0; i < ARRAY_SIZE(tlv_code_list); i++) {
		if (tlv_code_list[i].m_code == tlv->type &&
		    !IS_EEPROM_MAC(tlv_code_list[i].m_code)) {
			*name = malloc(strlen(tlv_code_list[i].m_name) + 1);
			strcpy(*name, tlv_code_list[i].m_name);
			return 0;
		}
	}

	*name = malloc(strlen("Unknown") + 1);
	strcpy(*name, "Unknown");

	return 1;
}

void show_eeprom(struct eeprom_data *eeprom)
{
	int tlv_end;
	int curr_tlv;
	struct eeprom_header *eeprom_hdr = (struct eeprom_header *)eeprom->data;
	struct tlv_field *eeprom_tlv;
	uint32_t crc;
	char *name = NULL;

	if (is_valid_tlvinfo_header(eeprom_hdr)) {
		printf("EEPROM does not contain data in a valid TlvInfo format.\n");
		return;
	}

	crc = crc_32(&eeprom->data[sizeof(struct eeprom_header)], ntohl(eeprom_hdr->totallen));
	printf("TlvInfo Header:\n");
	printf("   Version:      %u\n", ntohs(eeprom_hdr->version));
	printf("   Total Length: %d\n", ntohl(eeprom_hdr->totallen));
	printf("   CRC:          0x%x [%s]\n", ntohl(eeprom_hdr->crc32),
	       crc == ntohl(eeprom_hdr->crc32) ? "valid" : "invalid");

	printf("TLV Name             Len\n");
	printf("-------------------- ---\n");

	curr_tlv = sizeof(struct eeprom_header);
	tlv_end = sizeof(struct eeprom_header) + ntohl(eeprom_hdr->totallen);

	while (curr_tlv < tlv_end) {
		eeprom_tlv = (struct tlv_field *)&eeprom->data[curr_tlv];
		if (!is_valid_tlv(eeprom_tlv)) {
			printf("Invalid TLV field starting at EEPROM offset %d\n", curr_tlv);
			return;
		}

		tlv_type2name(eeprom_tlv, &name);
		printf("%-20s 0x%02X\n", name, ntohs(eeprom_tlv->length));
		if (name)
			free(name);
		curr_tlv += sizeof(struct tlv_field) + ntohs(eeprom_tlv->length);
	}

	return;
}

int read_sys_eeprom(void *eeprom_data, const char *target_device, int offset, int len)
{
	FILE *fptr;
	int count = 0;
	const char *device;

	device = target_device ? target_device : EEPROM_FILE_PATH;

	fptr = fopen(device, "rb");
	if (!fptr) {
		fprintf(stderr, "Cannot open file for reading\n");
		return 1;
	}

	fseek(fptr, offset, SEEK_SET);
	count = fread(eeprom_data, 1, len, fptr);
	if (count < len) {
		fprintf(stderr, "Reading %s file failed\n", device);
		return 1;
	}

	fclose(fptr);
	return 0;
}

int read_file_to_buf(const char *filename, char **out_buf, size_t *target_size) {
	FILE *fptr;

	fptr = fopen(filename, "rb");
	if (!fptr) {
		fprintf(stderr, "Cannot open file for reading\n");
		return -1;
	}

	fseek(fptr, 0, SEEK_END);
	*target_size = ftell(fptr);
	fseek(fptr, 0, SEEK_SET);

	*out_buf = malloc(*target_size);
	fread(*out_buf, 1, *target_size, fptr);

	fclose(fptr);
	return 0;
}

int read_eeprom(struct eeprom_data *eeprom, const char *target_device)
{
	uint32_t crc;
	struct eeprom_header tmp_header;
	struct eeprom_header *eeprom_hdr;

	if (read_sys_eeprom((struct eeprom_header *)&tmp_header, target_device, 0,
	    sizeof(struct eeprom_header))) {
		fprintf(stderr, "Unable to read eeprom\n");
		return 1;
	}

	if (is_valid_tlvinfo_header(&tmp_header)) {
		fprintf(stderr, "Invalid TLV header found\n");
		return 1;
	}

	if (read_sys_eeprom(eeprom->data, target_device, 0,
	    sizeof(struct eeprom_header) + ntohl(tmp_header.totallen))) {
		fprintf(stderr, "Unable to read eeprom\n");
		return 1;
	}

	eeprom_hdr = (struct eeprom_header *)eeprom->data;

	crc = crc_32(&eeprom->data[sizeof(struct eeprom_header)], ntohl(eeprom_hdr->totallen));
	if (crc != ntohl(eeprom_hdr->crc32)) {
		fprintf(stderr, "Invalid crc\n");
		return 1;
	}

	return 0;
}

void init_eeprom_header(struct eeprom_data *eeprom)
{
	struct eeprom_header *eeprom_hdr = (struct eeprom_header *)eeprom->data;

	strcpy(eeprom_hdr->magic, EEPROM_MAGIC);
	eeprom_hdr->version = htons(EEPROM_VERSION);
	eeprom_hdr->totallen = htonl(0);
	eeprom_hdr->crc32 = htonl(0);
}

void update_crc(struct eeprom_data *eeprom)
{
	uint32_t crc;
	struct eeprom_header *eeprom_hdr = (struct eeprom_header *)eeprom->data;
	unsigned char *data_payload = (unsigned char *)&eeprom->data[sizeof(struct eeprom_header)];

	crc = crc_32(data_payload, ntohl(eeprom_hdr->totallen));
	eeprom_hdr->crc32 = htonl(crc);
}

int tlvinfo_delete_tlv(struct eeprom_data *eeprom, char *key)
{
	int eeprom_index;
	int tlength;
	struct eeprom_header * eeprom_hdr = (struct eeprom_header *)eeprom->data;
	struct tlv_field * eeprom_tlv;

	if (!tlvinfo_find_tlv(eeprom, key, &eeprom_index)) {
		eeprom_tlv = (struct tlv_field *) &eeprom->data[eeprom_index];

		tlength = sizeof(struct tlv_field) + ntohs(eeprom_tlv->length);

		memcpy(&eeprom->data[eeprom_index],
		       &eeprom->data[eeprom_index + tlength],
		       sizeof(struct eeprom_header) + ntohl(eeprom_hdr->totallen) - eeprom_index - tlength);

		eeprom_hdr->totallen = htonl(ntohl(eeprom_hdr->totallen) - tlength);
		update_crc(eeprom);
		return 1;
	}

	return 0;
}

int create_mac_payload(char *mac, char *arg, char *iface)
{
	struct mac_data *payload = (struct mac_data *)mac;
	int iface_len;
	int status;

        status = sscanf(arg, "%2hhx:%2hhx:%2hhx:%2hhx:%2hhx:%2hhx",
                        &payload->byte[0], &payload->byte[1], &payload->byte[2],
                        &payload->byte[3], &payload->byte[4], &payload->byte[5]);

	if (status != MAC_SIZE_RAW)
		return -1;

	iface_len = strlen(iface);
	memcpy(payload->iface, iface, iface_len);

	return 0;
}

int resolve_tcode(char *strkey)
{
	int i;

	if (strstr(strkey, "GENERIC_MAC_"))
		return EEPROM_ATTR_MAC;

	for (i = 0; i < ARRAY_SIZE(tlv_code_list); i++) {
		if (strcmp(strkey, tlv_code_list[i].m_name) == 0)
			return tlv_code_list[i].m_code;
	}

	return -1;
}

int find_empty_mac_slot(struct eeprom_data *eeprom)
{
	int tlv_end, curr_tlv, i;
	unsigned int occupied_slot[EEPROM_ATTR_MAC_LAST - EEPROM_ATTR_MAC];
	struct eeprom_header *eeprom_hdr = (struct eeprom_header *)eeprom->data;
	struct tlv_field *eeprom_tlv;

	memset(occupied_slot, 0, sizeof(occupied_slot));

	curr_tlv = sizeof(struct eeprom_header);
	tlv_end = sizeof(struct eeprom_header) + ntohl(eeprom_hdr->totallen);

	while (curr_tlv < tlv_end) {
		eeprom_tlv = (struct tlv_field *)&eeprom->data[curr_tlv];
		if (eeprom_tlv->type >= EEPROM_ATTR_MAC_FIRST &&
		    eeprom_tlv->type <= EEPROM_ATTR_MAC_LAST) {
			occupied_slot[eeprom_tlv->type - EEPROM_ATTR_MAC_FIRST] = 1;
		}
		curr_tlv += sizeof(struct tlv_field) + ntohs(eeprom_tlv->length);
	}

	for (i = 0; i < ARRAY_SIZE(occupied_slot); i++) {
		if (occupied_slot[i] == 0)
			return i + EEPROM_ATTR_MAC_FIRST;
	}

	return -1;
}

int tlvinfo_add_tlv(struct eeprom_data *eeprom, char *strkey, char *strval, int size)
{
	struct eeprom_header *eeprom_hdr = (struct eeprom_header *)eeprom->data;
	struct tlv_field *eeprom_tlv;
	int new_tlv_len = 0;
	char *data = NULL;
	int eeprom_index;
	size_t max_size = eeprom->size - sizeof(struct eeprom_header);
	int tcode;
	char *iface;
	int iface_len;
	int temp_tcode;

	eeprom_index = sizeof(struct eeprom_header) + ntohl(eeprom_hdr->totallen);
	eeprom_tlv = (struct tlv_field *)&eeprom->data[eeprom_index];

	tcode = resolve_tcode(strkey);
	if (tcode < 0) {
		fprintf(stderr, "Incorrect KEY\n");
		return -1;
	}

	switch (tcode) {
		case EEPROM_ATTR_MAC:
			iface = strrchr(strkey, '_') + 1;
			iface_len = strlen(iface);
			new_tlv_len = MAC_SIZE_RAW + iface_len;
			data = (char *)malloc(new_tlv_len);

			if (create_mac_payload(data, strval, iface)) {
				free(data);
				fprintf(stderr, "Incorrect MAC address format\n");
				return -1;
			}

			temp_tcode = find_empty_mac_slot(eeprom);
			if (temp_tcode == -1) {
				free(data);
				fprintf(stderr, "All MAC splots are occupied\n");
				return -1;
			}

			eeprom_tlv->type = temp_tcode;
			eeprom_tlv->length = htons(new_tlv_len);
			break;
		default:
			new_tlv_len = (size > 0) ? size : strlen(strval);
			data = (char *)malloc(new_tlv_len);
			memcpy(data, strval, new_tlv_len);
			eeprom_tlv->type = tcode;
			eeprom_tlv->length = htons(new_tlv_len);
			break;
	}

	if ((ntohl(eeprom_hdr->totallen) + sizeof(struct tlv_field) + new_tlv_len) > max_size) {
		fprintf(stderr, "There is not enough room in the EERPOM to save data.\n");
		free(data);
		return -1;
	}

	memcpy(eeprom_tlv->value, data, new_tlv_len);
	eeprom_hdr->totallen = htonl(ntohl(eeprom_hdr->totallen) + sizeof(struct tlv_field) + new_tlv_len);
	update_crc(eeprom);

	free(data);

	return 0;
}

int prog_eeprom(struct eeprom_data *eeprom, const char *target_device)
{
	FILE *fptr;
	size_t eeprom_len;
	struct eeprom_header *eeprom_hdr = (struct eeprom_header *)eeprom->data;
	size_t write_size;

	eeprom_len = sizeof(struct eeprom_header) + ntohl(eeprom_hdr->totallen);
	fptr = fopen(target_device ? target_device : EEPROM_FILE_PATH, "wb");
	if (!fptr) {
		fprintf(stderr, "Cannot open file for writing\n");
		return -1;
	}

	write_size = target_device ? eeprom->size : eeprom_len;
	if (0 >= fwrite(eeprom->data, 1, write_size, fptr)) {
		fprintf(stderr, "Write file failed\n");
		fclose(fptr);
		return -1;
	}

	fclose(fptr);
	return 0;
}

size_t detect_eeprom_size(const char *path)
{
	size_t size;
	FILE *eeprom_file = fopen(path ? path : EEPROM_FILE_PATH, "rb");
	if (!eeprom_file) {
		fprintf(stderr, "Cannot open file for reading\n");
		return -1;
	}

	fseek(eeprom_file, 0, SEEK_END);
	size = ftell(eeprom_file);

	fclose(eeprom_file);
	return size;
}

int collect_eeprom_info(struct eeprom_data *eeprom, const char *target_device)
{
	size_t eeprom_size = detect_eeprom_size(target_device);

	if (eeprom_size <= 0) {
		fprintf(stderr, "Unable to detect EEPROM size\n");
		exit(0);
	}

	eeprom->size = eeprom_size;
	return 0;
}

void cmd_usage(int status)
{
	static const char *usage =
	    "Usage: sys-eeprom [-h] [-l] [-e] [-g <code>] [-s <code>=<value> | -s <code> -f <filename>] [-d] [-t <file>]\n"
	    "Show and update system EEPROM data.\n\n"
	    "Options:\n"
	    "  -h, --help               Show this help\n"
	    "  -l, --list               Show supported keys\n"
	    "  -g, --get <code>         Retrieve the value of the specified key\n"
	    "  -s, --set <code>=<value> Assign the specified key with a new value\n"
	    "  -f, --file               Read the value from a file\n"
	    "  -e, --erase              Clear the EEPROM data\n"
	    "  -d, --dump               Show all available values in the EEPROM\n"
	    "  -t, --target             Target EEPROM file\n";

	fprintf(status ? stderr : stdout, "%s", usage);
        exit(status);
}

int main(int argc, char * const argv[])
{
	char *subopts_value, *split_symbol;
	int c, option_index;
	char *tlv_value = NULL;
	size_t tlv_size = 0;
	int tlv_index;
	struct eeprom_data eeprom;
	struct tlv_field *eeprom_tlv;
	char *value_file_path = NULL;
	char *subopts_key = NULL;
	char *target_device = NULL;
	size_t payload_size = 0;
	int rv = 0;

	int uniq_action = 0;
	int erase_eeprom = 0;
	int set_tlv = 0;
	int get_value = 0;
	int dump_values = 0;

	const struct option long_options[] = {
		{"help", no_argument, 0, 'h'},
		{"list", no_argument, 0, 'l'},
		{"erase", no_argument, 0, 'e'},
		{"set", required_argument, 0, 's'},
		{"get", required_argument, 0, 'g'},
		{"file", required_argument, 0, 'f'},
		{"dump", no_argument, 0, 'd'},
		{"target", required_argument, 0, 't'},
		{0, 0, 0, 0},
	};

	while ((c = getopt_long(argc, argv, "hles:g:f:dt:", long_options, &option_index)) != -1) {
		switch (c) {
			case 'l':
				show_tlv_code_list();
				exit(0);
				break;
			case 'e':
				if (uniq_action)
					exit(1);
				erase_eeprom = 1;
				uniq_action = 1;
				break;
			case 's':
				if (!optarg)
					cmd_usage(1);

				if (uniq_action)
					exit(1);

				set_tlv = 1;
				uniq_action = 1;
				split_symbol = strchr(optarg, '=');
				if (!split_symbol) {
					subopts_key = optarg;
					break;
				}

				subopts_value = split_symbol + 1;
				*split_symbol = '\0';
				subopts_key = optarg;
				break;
			case 'f':
				value_file_path = optarg;
				break;
			case 'g':
				if (uniq_action)
					exit(1);
				subopts_key = optarg;
				get_value = 1;
				uniq_action = 1;
				break;
			case 'd':
				if (uniq_action)
					exit(1);
				dump_values = 1;
				uniq_action = 1;
				break;
			case 't':
				target_device = optarg;
				break;
			case '?':
				cmd_usage(1);
				break;
			default:
				cmd_usage(c != 'h');
				break;
		}
	}

	if (argc <= 1) {
		cmd_usage(1);
		exit(1);
	}

	collect_eeprom_info(&eeprom, target_device);
	eeprom.data = malloc(eeprom.size);
	memset(eeprom.data, '\0', eeprom.size);

	if (dump_values) {
		if (read_eeprom(&eeprom, target_device)) {
			rv = 1;
			goto finish;
		}
		show_eeprom(&eeprom);
	}

	if (value_file_path) {
		if (read_file_to_buf(value_file_path, &subopts_value, &payload_size)) {
			fprintf(stderr, "Unable to read file %s\n", value_file_path);
			rv = 1;
			goto finish;
		}
	}

	if (erase_eeprom) {
		init_eeprom_header(&eeprom);
		prog_eeprom(&eeprom, target_device);
	}

	if (get_value) {
		if (read_eeprom(&eeprom, target_device)) {
			rv = 1;
			goto finish;
		}

		if (tlvinfo_find_tlv(&eeprom, subopts_key, &tlv_index)) {
			fprintf(stderr, "TLV is not present in EEPROM\n");
			rv = 1;
			goto finish;
		}

		eeprom_tlv = (struct tlv_field *)&eeprom.data[tlv_index];
		decode_tlv_value(eeprom_tlv, &tlv_value, &tlv_size);
		print_value(tlv_value, tlv_size);
	}

	if (set_tlv) {
		if (read_eeprom(&eeprom, target_device)) {
			rv = 1;
			goto finish;
		}

		tlvinfo_delete_tlv(&eeprom, subopts_key);
		if (subopts_value && tlvinfo_add_tlv(&eeprom, subopts_key, subopts_value, payload_size)) {
			fprintf(stderr, "TLV addition failed\n");
			rv = 1;
			goto finish;
		}
		prog_eeprom(&eeprom, target_device);
	}

finish:
	if (value_file_path)
		free(subopts_value);

	if (tlv_value)
		free(tlv_value);

	if (eeprom.data)
		free(eeprom.data);

	return rv;
}
