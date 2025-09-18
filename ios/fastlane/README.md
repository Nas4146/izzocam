fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Build and upload to TestFlight

### ios release

```sh
[bundle exec] fastlane ios release
```

Push a new release build to the App Store

### ios bump_version

```sh
[bundle exec] fastlane ios bump_version
```

Increment version number (major.minor.patch)

### ios version_info

```sh
[bundle exec] fastlane ios version_info
```

Get current version and build number

### ios release_candidate

```sh
[bundle exec] fastlane ios release_candidate
```

Build release candidate for testing

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
