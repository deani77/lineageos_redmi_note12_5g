# Source verification and outstanding dependencies

Checked 2026-10-22 through GitHub repository refs and file contents.

## Verified source configuration

All four repositories below expose a `lineage-23.2` branch; the local manifest
pins the inspected commits:

| Checkout path | Repository | Commit |
| --- | --- | --- |
| `device/xiaomi/gemstone` | [xiaomi-sm6375-devs/android_device_xiaomi_gemstone](https://github.com/xiaomi-sm6375-devs/android_device_xiaomi_gemstone/tree/aa03d44fb92edb9220187a2ebe5706b446a229e5) | `aa03d44fb92edb9220187a2ebe5706b446a229e5` |
| `device/xiaomi/sm6375-common` | [xiaomi-sm6375-devs/android_device_xiaomi_sm6375-common](https://github.com/xiaomi-sm6375-devs/android_device_xiaomi_sm6375-common/tree/4cd108d5cd933e5cdaf1293bee233621e8008ac8) | `4cd108d5cd933e5cdaf1293bee233621e8008ac8` |
| `kernel/xiaomi/sm6375` | [xiaomi-sm6375-devs/android_kernel_xiaomi_moonstone](https://github.com/xiaomi-sm6375-devs/android_kernel_xiaomi_moonstone/tree/dfbf1e20a3bd42f81c16d80796066a59124107bc) | `dfbf1e20a3bd42f81c16d80796066a59124107bc` |
| `hardware/xiaomi` | [LineageOS/android_hardware_xiaomi](https://github.com/LineageOS/android_hardware_xiaomi/tree/b72a93939350632d3033b1218b10af0f9c0ae5c2) | `b72a93939350632d3033b1218b10af0f9c0ae5c2` |

The [device BoardConfig](https://github.com/xiaomi-sm6375-devs/android_device_xiaomi_gemstone/blob/aa03d44fb92edb9220187a2ebe5706b446a229e5/BoardConfig.mk)
sets `TARGET_OTA_ASSERT_DEVICE := moonstone,sunstone,gemstone` and
`TARGET_KERNEL_CONFIG := moonstone_defconfig`. Its
[product definition](https://github.com/xiaomi-sm6375-devs/android_device_xiaomi_gemstone/blob/aa03d44fb92edb9220187a2ebe5706b446a229e5/lineage_gemstone.mk)
sets `PRODUCT_NAME := lineage_gemstone`, model `22111317G`, and a
`sunstone_eea` fingerprint. This establishes source-declared Redmi Note 12 5G
support, not an independent boot test. The kernel's
[moonstone_defconfig](https://github.com/xiaomi-sm6375-devs/android_kernel_xiaomi_moonstone/blob/dfbf1e20a3bd42f81c16d80796066a59124107bc/arch/arm64/configs/moonstone_defconfig)
exists in the pinned tree.

The [common BoardConfig](https://github.com/xiaomi-sm6375-devs/android_device_xiaomi_sm6375-common/blob/4cd108d5cd933e5cdaf1293bee233621e8008ac8/BoardConfigCommon.mk)
uses `kernel/xiaomi/sm6375`, which is why the moonstone kernel is mapped to
that path. The common tree's `lineage.dependencies` instead names
`android_kernel_xiaomi_sm6375`; do not blindly follow that generic filename
to an old kernel branch. The manifest explicitly selects the verified moonstone
kernel and supplies `hardware/xiaomi`. The product is already local, so the
build selects it directly without relying on roomservice to choose a kernel.

The [LineageOS base manifest](https://github.com/LineageOS/android/tree/lineage-23.2)
exists (observed head `9776e518de506f610218c4caa6c1fddff46873af`).
Its `snippets/lineage.xml` supplies Qualcomm platform projects, including the
SM8350 audio stack, display stack and sepolicy. These remain upstream branch
dependencies and have not all been cloned or compiled here.

## Missing proprietary vendor dependencies

Required generated makefiles and blobs:

- `vendor/xiaomi/gemstone/BoardConfigVendor.mk`,
  `gemstone-vendor.mk`, and populated `proprietary/`.
- `vendor/xiaomi/sm6375-common/sm6375-common-vendor.mk` and populated
  `proprietary/`.

No matching maintainer-proven LineageOS 23.2 public vendor pair was verified in
this search. Public crDroid vendor repositories were found, but their current
default branches target crDroid 17.0; they are deliberately excluded because
matching device names alone do not establish blob or build compatibility.

The upstream [gemstone extraction script](https://github.com/xiaomi-sm6375-devs/android_device_xiaomi_gemstone/blob/aa03d44fb92edb9220187a2ebe5706b446a229e5/extract-files.py)
calls `ExtractUtils.device_with_common` for gemstone and sm6375-common.
Use this script from the synced device directory with a suitable extracted
source dump, following its `--help` and upstream extract-utils instructions:

```bash
cd "$ROM_SOURCE_DIR/device/xiaomi/gemstone"
./extract-files.py --help
./extract-files.py /absolute/path/to/compatible/extracted-dump
```

Do not expect a random stock dump to satisfy all pinned entries. The
[device proprietary list](https://github.com/xiaomi-sm6375-devs/android_device_xiaomi_gemstone/blob/aa03d44fb92edb9220187a2ebe5706b446a229e5/proprietary-files.txt)
names `OS2.0.9.0.UMQEUXM (SUNSTONEGlobal)` for unpinned blobs.
The [common list](https://github.com/xiaomi-sm6375-devs/android_device_xiaomi_sm6375-common/blob/4cd108d5cd933e5cdaf1293bee233621e8008ac8/proprietary-files.txt)
also references `dada: OS2.0.217.0.WOCMIXM`. Resolve all per-file pinned
hashes and extraction errors, then regenerate both vendor trees using the
upstream scripts. A compatible maintainer build dump may supply the combined
files; that route and extraction were not tested in this session.
Firmware requirements for the exact regional phone variant still need
maintainer confirmation; a blob fingerprint is not a flashing instruction.

## Build evidence and permissions

- Target repository inspected as public and empty; GitHub connection reports
  push/admin permission. Existing user files were therefore not overwritten.
- Actions is enabled and [configuration CI passed](https://github.com/deani77/lineageos_redmi_note12_5g/actions/runs/39705049345).
  Local manifest/lock checks, shell syntax and YAML parsing also passed. The
  missing-dependency check was exercised and correctly failed with explicit paths.
- The Actions UI confirms no self-hosted runner is registered for this repository.
  The rom-build environment and ROM_SOURCE_DIR still need provisioning.
  Administrative Actions policy and artifact quota remain unverified because the
  connector rejects the permissions endpoint.
- The first build workflow definition had an invalid job-scope runner context.
  This was fixed in commit cf416e01a2679ef77f023c63a481640314b51fff; GitHub now
  displays the correctly named manual build workflow with a Run workflow button.
  The historical failed validation run did not allocate a runner or compile a ROM.
- This execution host is macOS ARM64 and has no repo tool. An ordinary Git clone
  also failed because shell network DNS is restricted. Source inspection used
  the connected GitHub API instead.
- No full source sync, extraction, compiler invocation, boot or device test was
  completed. A maintainer's downloadable ROM does not prove this configuration
  reproduces that ROM, and is not claimed as a successful build here.
