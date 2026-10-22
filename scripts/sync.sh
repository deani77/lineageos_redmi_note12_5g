#!/usr/bin/env bash
# Run only against a dedicated Android source directory.
set -euo pipefail
config_dir="$(cd "$(dirname "$0")/.." && pwd)"
: "${ROM_SOURCE_DIR:?Set ROM_SOURCE_DIR to an absolute dedicated Android source directory}"
[[ "$ROM_SOURCE_DIR" = /* ]] || { echo "ROM_SOURCE_DIR must be absolute"; exit 1; }
command -v repo >/dev/null
mkdir -p "$ROM_SOURCE_DIR"
cd "$ROM_SOURCE_DIR"
if [[ ! -d .repo ]]; then
  # Refuse to initialize over unrelated files.
  [[ -z "$(ls -A)" ]] || { echo "Source directory is not empty"; exit 1; }
  repo init -u https://github.com/LineageOS/android.git -b lineage-23.2 --git-lfs
else
  origin="$(git -C .repo/manifests remote get-url origin)"
  branch="$(git -C .repo/manifests config branch.default.merge)"
  [[ "$origin" = https://github.com/LineageOS/android.git && "$branch" = refs/heads/lineage-23.2 ]] ||
    { echo "Existing checkout is not the expected LineageOS 23.2 manifest"; exit 1; }
fi
mkdir -p .repo/local_manifests
destination=.repo/local_manifests/gemstone.xml
if [[ -e "$destination" ]]; then
  cmp "$config_dir/manifests/gemstone.xml" "$destination" ||
    { echo "Existing gemstone.xml differs; reconcile it manually"; exit 1; }
else
  cp "$config_dir/manifests/gemstone.xml" "$destination"
fi
# Do not force-sync, reset or delete existing projects.
repo sync -c --no-tags -j4
repo manifest -r -o resolved-manifest.xml
echo "Sync complete. Supply vendor trees, then run scripts/validate.py --source-root here."
