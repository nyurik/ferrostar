# Contributing to Ferrostar

We're stoked that you're interested in working on Ferrostar!
This contribution guide will get you started developing in no time,
as well as provide some guidelines to follow when submitting an issue or PR.

## Best Practices for Contributions

We welcome contributions from community!
Due to the size and complexity of the code, below are some best practices that ensure smooth collaboration.

It is a good idea to discuss large proposed changes before proceeding to an issue ticket or PR.
The project team is active in the following forums:

* For informal chat discussions, visit the `#ferrostar` channel in the OSMUS Slack.
  You can get an invite to the workspace at [slack.openstreetmap.us](https://slack.openstreetmap.us/).
* For larger discussions where it would be desirable to have wider input / a less ephemeral record,
  consider starting a thread on [GitHub Discussions](https://github.com/stadiamaps/ferrostar/discussions).
  This makes it easier to find and reference the discussion in the future.

### Testing

Both new features and bugfixes should update or add unit test cases where possible
to prevent regressions and demonstrate correctness.
This is particularly true of the common core.

We are a bit more lax with the frontend code as this may be difficult or impractical to test.
We have been gradually introducing snapshot testing on iOS as a way to overcome these difficulties,
but it's not perfect.
Suggestions welcome for Android.

### New Features

For new features, you should generally start by opening a new issue.
That will allow for separate tracking of discussion of the feature itself
and (if you're proposing code as well) the implementation of the feature.

### Bug Fixes

If you've identified a significant bug, or one that you don't intend to fix yourself,
please write up an issue ticket describing the problem.
For minor or straightforward bug fixes, feel free to proceed directly to a PR.

### Pull Request Tips

To speed up reviews, it's helpful if you enable edits from maintainers when opening the PR.
In the case of minor changes, formatting, or style nitpicks, we can make edits directly to avoid wasting your time.
In order to enable edits from maintainers, **you'll need to make the PR from a fork owned an individual**,
not an organization.
GitHub org-owned forks lack this flexibility.

Note: we enforce formatting checks on PRs.
If you forget to do this, CI will eventually fail on your PR.

## Preparing your Development Environment


To ensure that everything can be developed properly in parallel,
we use a monorepo structure.
This, combined with CI, will ensure that changes in the core must be immediately reflected in platform code
like Apple and Android.

Let's look at what's involved to get hacking on each platform.

### Rust

1. Install [Rust](https://www.rust-lang.org/).
   If at all possible, install `rustup`.
   We use [rust-toolchain.yml](common/rust-toolchain.yml)
   to synchronize the toolchain and install targets automatically
   (otherwise you will need to manage toolchains manually).
2. Open the cargo workspace (`common/`) in your preferred editing environment. 

The Rust project is a cargo workspace,
and nothing beyond the above should be needed to start hacking!

Run `cargo fmt` from the `common` directory before committing to ensure consistent formatting.

### iOS

1. Install the latest version of Xcode.
2. Install the Xcode Command Line Tools.

```shell
xcode-select --install
```

3. Install [`swiftformat`](https://github.com/nicklockwood/SwiftFormat).
4. Since you're developing locally, set `let useLocalFramework = true` in `Package.swift`.
   (TODO: Figure out a way to extract this so it doesn't get accidentally committed.) 
5. Run the iOS build script:

```shell
cd common
./build-ios.sh
```

**IMPORTANT:** every time you make changes to the common core,
you will need to run [`build-ios.sh`](common/build-ios.sh) to see your changes on iOS!
We want to integrate this into the Xcode build flow in the future,
but at the time of this writing,
it is not possible with the Swift package flow.
Further, the "normal" Xcode build flow always assumes xcframeworks can't change during build,
so it processes them before any other build rules.
Given these limitations, we opted for a shell script until further notice.

5. Open the Swift package in Xcode.
   (NOTE: Due to the quirks of how SPM is designed,
   Package.swift must live in the repo root.
   This makes the project view in Xcode slightly more cluttered,
   but there isn't much we can do about this given how SPM works.)

Run `swiftformat .` from the `apple` directory before committing
to ensure consistent formatting.

### Android

1. Install [Android Studio](https://developer.android.com/studio).
2. Install cargo-ndk to allow gradle to build the local library `libferrostar.so` and `libuniffi_ferrostar.so`. 
   With cargo-ndk installed you can load and sync Android Studio then build the demo app allowing gradle to 
   automatically build what it needs.

```sh
cargo install cargo-ndk
```

3. Ensure that the latest NDK is installed
   (refer to the `ndkVersion` number in [`core/build.gradle`](android/core/build.gradle)
   and ensure you have the same version available).
   This is easiest to install via Android Studio's SDK Manager (under SDK Tools > NDK).
4. Set up Github Packages authentication if you haven't already done so.
   
   - Get a Personal Access Token with permission to read packages
   - Save your GitHub username and PAT in a Gradle properties file (ex: ~/.gradle/gradle.properties) like so:
   - See [GitHub's guide](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-gradle-registry#authenticating-to-github-packages) for more details.
   
   ```
   gpr.user=username
   gpr.key=key
   ```
5. Open the Gradle workspace ('android/') in Android Studio.
   Gradle builds automatically ensure the core is built,
   so there are no funky scripts needed as on iOS.

Run the `ktfmtFormat` gradle action before committing to ensure consistent formatting.

## Writing & Running Tests

### Common Core

Run `cargo test -p ferrostar-core` from within the `common` directory to run tests.

### iOS

Run unit tests as usual from within Xcode.

### Android

At the moment, we need to use Android tests,
but want to remove this requirement in the future as it is extremely expensive.
So, the recommended way to run all tests is `./gradlew connectedCheck`. 

## Code Conventions

* Format all Rust code using `cargo fmt`
* Run `cargo clippy` and either fix any warnings or document clearly why you think the linter should be ignored
* All iOS code must be written in Swift
* TODO: Swiftlint and swift-format?
* All Android code must be written in Kotlin
* TODO: ktlint

## Changelog Conventions

NOTE: We'll be *extremely* loose with this
until we have solid beta quality releases for both iOS and Android.

What warrants a changelog entry?

- Any change that affects the public API, visual appearance or user security *must* have a changelog entry
- Any performance improvement or bugfix *should* have a changelog entry
- Any contribution from a community member *may* have a changelog entry, no matter how small
- Any documentation related changes *should not* have a changelog entry
- Any regression change introduced and fixed within the same release *should not* have a changelog entry
- Any internal refactoring, technical debt reduction, test, or benchmark related change *should not* have a changelog entry

How to add your changelog?

- Edit the [`CHANGELOG.md`](CHANGELOG.md) file directly, inserting a new entry at the top of the appropriate list
- Any changelog entry should be descriptive and concise; it should explain the change to a reader without context

