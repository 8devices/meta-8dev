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

## Quick Start

### Building Image

Start the image by specifying target `DISTRO` for desired `MACHINE`:

   ```
   `DISTRO=8dev-basic bitbake 8dev-image-base
   ```

## Support and Contributing

Refer to parent [layer collection README](../README.md) for rules
to reporting issues, submitting code changes and patches.

## Maintainers

	Edvinas Stunžėnas <edvinas@8devices.com>

