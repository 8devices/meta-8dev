# meta-8dev-basic

This layer contains 8devices basic distro and images configuration.
Mainly intended to provide shared baseline tools and utilities for
initial 8devices products testing, bring-up or HW validation. The
layer is primarily targeted to be used with `meta-8dev-bsp` layer
however there is no hard dependency.

## Dependencies

This layer depends on:

	URI: https://git.yoctoproject.org/poky
	layers: meta
	branch: scarthgap

	URI: https://git.openembedded.org/meta-openembedded
	layers: meta-networking
	branch: scarthgap

	URI: https://github.com/sbabic/meta-swupdate.git
	layers: meta-swupdate
	branch: scarthgap

## Quick Start

### Building update image

The update image is used to upgrade the device software. The following command
can be used to build it:

   ```
   DISTRO=8dev-basic bitbake update-image-8dev-base
   ```

`DISTRO` and `MACHINE` variables can be used to specify the target
distribution and machine, respectively.

### Building recovery image

The recovery image is used to recover the device or perform a manual update. The
following command can be used to build it:

   ```
   DISTRO=8dev-basic bitbake 8dev-image-base
   ```

This command support `DISTRO` and `MACHINE` variables as well.

## Support and Contributing

Refer to parent [layer collection README](../README.md) for rules
to reporting issues, submitting code changes and patches.

## Maintainers

	Edvinas Stunžėnas <edvinas@8devices.com>

