# meta-8dev-bsp

The official OpenEmbedded/Yocto BSP layer for 8devices products.
This layer provides machine configuration and packages extensions
to enable software build for 8devices modules and boards.

## Dependencies

This layer depends on:

	URI: https://git.yoctoproject.org/poky
	layers: meta, meta-poky
	branch: scarthgap

	URI: https://git.openembedded.org/meta-openembedded
	layers: meta-oe
	branch: scarthgap

## Quick Start

### Supported Hardware

Following MACHINES are supported:

- tobufi-dvk -- TobuFi module based development kit
- robonode -- TobuFi module based UAV platform

### Building Image

Start the image by specifying target `MACHINE`:

   ```
   MACHINE="tobufi-dvk" bitbake core-image-base
   ```

## Support and Contributing

Refer to parent [layer collection README](../README.md) for rules
to reporting issues, submitting code changes and patches.

## Maintainers

	Edvinas Stunžėnas <edvinas@8devices.com>

