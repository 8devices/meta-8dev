# meta-8dev-bsp

The official OpenEmbedded/Yocto BSP layer for 8devices products.
This layer provides machine configuration and packages extensions
to enable software build for 8devices modules and boards.

## Dependencies

This layer depends on:

	URI: https://git.yoctoproject.org/poky
	layers: meta, meta-poky
	branch: wrynose

	URI: https://git.openembedded.org/meta-openembedded
	layers: meta-oe
	branch: wrynose

	URI: https://github.com/qualcomm-linux/meta-qcom.git
	layers: meta-qcom
	branch: wrynose

## Quick Start

### Supported Hardware

Following MACHINES are supported:

- citron -- QCS6490-based Citron SOM; one multi-DTB image for every Citron
  carrier (Robonode Vision, Citron DVK, bare SOM)

### Building Image

Start the image by specifying target `MACHINE`:

   ```
   MACHINE="citron" bitbake core-image-base
   ```

## Support and Contributing

Refer to parent [layer collection README](../README.md) for rules
to reporting issues, submitting code changes and patches.

## Maintainers

	Edvinas Stunžėnas <edvinas@8devices.com>

