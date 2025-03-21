# meta-8dev

Collection of layers for the OE-core universe to enable 8devices products.

* **meta-8dev-bsp**: layer containing the recipes and sources for building
and operating 8devices system-on-module's (SoMs) and development kits (DVKs).
This includes machine configurations files, kernel configuration fragments
and patches, pre-built firmware binaries and debugging utilities.

* **meta-8dev-basic**: layer containing basic 8devices reference distribution
configuration files, services extensions, helper utilities and target system
optimisations targeted for meta-8dev-bsp supported machines to simplify their
software and the hardware evaluation.

> **See:** 8devices products
> - Wi-Fi SoMs https://www.8devices.com/wifi-soms
> - Premium SoMs https://www.8devices.com/premium-soms

> **Note:** glued reference SDK includ required dependencies and build
> instructions can be found at https://github.com/8devices/meta-8dev-sdk.

Please see the respective READMEs in the layer subdirectories

## Additional Documentation

For more information about [Yocto Project](https://www.yoctoproject.org) see
Yocto Project docs which can be found at:

 * https://docs.yoctoproject.org/singleindex.html

## Support

Please report bugs, request features, or ask questions through
[GitHub Issues](https://github.com/8devices/meta-8dev/issues).

Before submitting an issue, please:

1. Check if the issue has already been reported
2. Verify which layer and branch you're using
3. Include information about your environment and how to reproduce the issue
4. Attach relevant logs or screenshots

## Contributing

The preferred method for submitting fixes and updates is through
[GitHub pull-requests](https://github.com/8devices/meta-8dev/pulls).
All pull requests will be discussed within the GitHub pull-request
infrastructure.

When creating pull request, please:

- Keep pull requests focused on a single topic
- Explain why and what is being changed
- Rebase your branch before submitting the pull request
- Make sure your code follows the existing coding style
- Reference any related issues using the GitHub issue linking syntax
- Include in commit a 'Signed-off-by:' line
- For non-trivial changes, provide information how the changes were
  tested, and for any non-trivial or non-obvious testing setup also
  please provide details of that setup.

General contribution workflow, details and guidelines are described in
[Yocto Project Contributor Guide | Preparing Changes for Submission](https://docs.yoctoproject.org/dev/contributor-guide/submit-changes.html#preparing-changes-for-submission).

## Maintainers

	Edvinas Stunžėnas <edvinas@8devices.com>

