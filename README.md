# Unofficial LineageOS 23.2 for Redmi Note 12 5G

Build configuration for Android 16 using the unified **gemstone** device tree.
The upstream OTA assertions explicitly include **sunstone**, **moonstone**, and
**gemstone**. The community name **stone** is not the build product:
use `lineage_gemstone`. This configuration does not target the Redmi Note 12 4G.

**Status: source configuration inspected; no successful source sync, ROM compile,
boot, or hardware test has been performed here. Two proprietary vendor trees
remain unsupplied. Do not treat this repository as a tested flashable ROM.**

## What is included

- A local manifest with pinned device, SM6375 common, moonstone kernel, and Xiaomi
  hardware commits from verified `lineage-23.2` refs.
- A source lock and [source evidence/dependency report](docs/SOURCES.md).
- Configuration checks on ordinary GitHub-hosted runners.
- A manually dispatched ROM build for a dedicated Linux build runner, with logs,
  resolved source revisions, ROM artifacts and SHA-256 checksums.

This repository was empty when inspected on 2026-10-22. No existing files were
removed or replaced. It references upstream source repositories rather than
copying Android's entire multi-repository source tree.

## Prepare a build machine

Provision a dedicated Ubuntu 24.04 x86_64 machine with 64 GB RAM and at least
400 GiB free disk space (more is preferable). Install the current LineageOS
[Ubuntu build prerequisites](https://wiki.lineageos.org/devices/bluejay/build/#install-the-build-packages)
and Google's [repo tool](https://source.android.com/docs/setup/reference/repo).
That linked device guide is used only for host dependencies; its device commands
do not apply to gemstone. Required host commands include repo, Git, Git LFS,
Python 3, make, ninja, Java, lz4, zip, and unzip.

Set a dedicated absolute source directory, for example:

```bash
export ROM_SOURCE_DIR=/srv/android/lineage-23.2-gemstone
bash scripts/sync.sh
```

Sync uses the LineageOS `lineage-23.2` base manifest and this repository's
`manifests/gemstone.xml`. It refuses an unrelated existing checkout or a differing
existing gemstone manifest. It does not force-sync or reset projects. Existing
local manifests must be reconciled manually if they duplicate any project paths.

Supply the missing vendor trees as described in [SOURCES.md](docs/SOURCES.md).
Then check and build:

```bash
python3 scripts/validate.py --source-root "$ROM_SOURCE_DIR"
export ROM_LOG_DIR=/srv/android/gemstone-build-logs
bash scripts/build.sh
```

The target release is read from upstream `vars/aosp_target_release` (observed
`bp4a`), then lunch selects `lineage_gemstone-<release>-userdebug`.
The build runs `m bacon -j8`. These are unofficial development builds using
upstream test-key defaults; no private signing material is included.

## GitHub Actions

1. Enable Actions if disabled. Register a dedicated self-hosted Linux x64 runner
   with label `android-rom`; a standard free hosted runner is unsuitable for this
   full source build.
2. Create the repository environment `rom-build`, restrict it to `main`, and set
   its variable `ROM_SOURCE_DIR` to the absolute source directory. Provision the
   source checkout and proprietary trees on that runner first. For this public
   repository, keep the runner dedicated and restrict who can dispatch builds.
3. Run **Build unofficial LineageOS 23.2** from Actions on `main`.
   It checks resources, syncs non-destructively, validates dependencies, builds,
   and uploads artifacts only after a successful build command and fresh ROM ZIP.
   It never publishes a release or flashes a phone.

The full build runs only by manual dispatch on main; pull requests run only the
configuration checks on GitHub-hosted runners. The workflow requests read-only
repository permission and needs no repository token or signing secret.
Actual artifact upload also depends on Actions being enabled and storage quota.
Environment, runner registration and Actions settings were not provisioned or
verified by this session: the connector cannot inspect Actions permissions.
A build can queue indefinitely if no matching runner is registered.

Each build saves a resolved manifest because the base LineageOS projects still
track a branch. The four local additions are pinned; this is not a complete
immutable lock of the Android source tree until a resolved manifest is captured.

## Verification limits

Local configuration and shell checks are separate from compilation. Presence
checks do not certify that every proprietary blob exists or has the right ABI.
Only a full build followed by testing on the exact phone variant can establish
boot, camera, cellular/VoLTE, NFC, encryption, SELinux and OTA behavior.
No hardware compatibility guarantee is made.
