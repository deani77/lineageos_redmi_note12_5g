#!/usr/bin/env python3
"""Validate this configuration; optionally inspect an existing Android checkout."""
import argparse
import json
import pathlib
import re
import subprocess
import sys
import xml.etree.ElementTree as ET

HERE = pathlib.Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument("--source-root", type=pathlib.Path)
parser.add_argument("--remote", action="store_true")
args = parser.parse_args()
lock = json.loads((HERE / "sources.lock.json").read_text())
root = ET.parse(HERE / "manifests/gemstone.xml").getroot()
projects = root.findall("project")
assert len(projects) == len(lock["projects"]) == 4
assert len({p.attrib["path"] for p in projects}) == len(projects)
for item, project in zip(lock["projects"], projects):
    for key in ("name", "path", "revision"):
        assert project.attrib[key] == item[key], (key, item)
    assert re.fullmatch(r"[0-9a-f]{40}", item["revision"])
    if args.remote:
        url = "https://github.com/" + item["name"] + ".git"
        result = subprocess.run(
            ["git", "ls-remote", "--exit-code", url, "refs/heads/" + item["branch"]],
            check=True, capture_output=True, text=True, timeout=120)
        # A moving branch is informational: the manifest remains pinned.
        print(item["name"], "current head", result.stdout.split()[0],
              "pinned", item["revision"])
if args.source_root:
    source = args.source_root.resolve()
    required = [
        "build/envsetup.sh", "vendor/lineage/vars/aosp_target_release",
        "device/xiaomi/gemstone/AndroidProducts.mk",
        "device/xiaomi/sm6375-common/BoardConfigCommon.mk",
        "kernel/xiaomi/sm6375/arch/arm64/configs/moonstone_defconfig",
        "hardware/xiaomi/vintf/xiaomi_framework_compatibility_matrix.xml",
        "vendor/xiaomi/gemstone/BoardConfigVendor.mk",
        "vendor/xiaomi/gemstone/gemstone-vendor.mk",
        "vendor/xiaomi/sm6375-common/sm6375-common-vendor.mk",
    ]
    missing = [p for p in required if not (source / p).is_file()]
    for name in lock["missing"]:
        blobs = source / name / "proprietary"
        if not blobs.is_dir() or not any(p.is_file() for p in blobs.rglob("*")):
            missing.append(name + "/proprietary (populated blobs)")
    if missing:
        sys.exit("Missing build dependencies:\n  " + "\n  ".join(missing) +
                 "\nSee docs/SOURCES.md; do not substitute another ROM's blobs blindly.")
    board = (source / "device/xiaomi/gemstone/BoardConfig.mk").read_text()
    assert "moonstone,sunstone,gemstone" in board
    product = (source / "device/xiaomi/gemstone/lineage_gemstone.mk").read_text()
    assert "PRODUCT_NAME := lineage_gemstone" in product
    for item in lock["projects"]:
        head = subprocess.check_output(
            ["git", "-C", str(source / item["path"]), "rev-parse", "HEAD"],
            text=True).strip()
        assert head == item["revision"], ("Unexpected checkout revision", item["path"], head)
print("Configuration checks passed. This does not certify a ROM build or blob completeness.")
