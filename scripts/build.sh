#!/usr/bin/env bash
set -eo pipefail
config_dir="$(cd "$(dirname "$0")/.." && pwd)"
: "${ROM_SOURCE_DIR:?Set ROM_SOURCE_DIR}"
: "${ROM_LOG_DIR:?Set ROM_LOG_DIR to a directory outside the source tree}"
[[ "$(uname -sm)" = "Linux x86_64" ]] || { echo "Requires Linux x86_64"; exit 1; }
python3 "$config_dir/scripts/validate.py" --source-root "$ROM_SOURCE_DIR"
mkdir -p "$ROM_LOG_DIR"
cd "$ROM_SOURCE_DIR"
repo manifest -r -o "$ROM_LOG_DIR/resolved-manifest.xml"
# Android's environment scripts do not support nounset.
source build/envsetup.sh
source vendor/lineage/vars/aosp_target_release
lunch "lineage_gemstone-${aosp_target_release}-userdebug" 2>&1 | tee "$ROM_LOG_DIR/lunch.log"
started="$(date +%s)"
m bacon -j8 2>&1 | tee "$ROM_LOG_DIR/build.log"
# A successful command alone is insufficient: require an output archive.
shopt -s nullglob
roms=(out/target/product/gemstone/lineage-23.2-*-UNOFFICIAL-gemstone.zip)
(( ${#roms[@]} > 0 )) || { echo "No LineageOS 23.2 unofficial output ZIP found"; exit 1; }
for rom in "${roms[@]}"; do
  (( $(stat -c %Y "$rom") >= started )) ||
    { echo "Output archive predates this build: $rom"; exit 1; }
done
sha256sum "${roms[@]}" > "$ROM_LOG_DIR/SHA256SUMS"
