#!/bin/bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

# Pass a simulator UDID to choose a device; otherwise use an available iPhone.
simulator_id="${1:-}"
if [[ -z "$simulator_id" ]]; then
  simulator_id="$(xcrun simctl list devices available --json | python3 -c '
import json, sys
devices = [device for runtime, group in json.load(sys.stdin)["devices"].items()
           if ".iOS-" in runtime and int(runtime.split(".iOS-")[1].split("-")[0]) >= 17
           for device in group
           if device["name"].startswith("iPhone") and device.get("isAvailable", False)]
if not devices:
    sys.exit("No available iPhone simulator. Install an iOS runtime in Xcode Settings.")
devices.sort(key=lambda device: device["state"] != "Booted")
print(devices[0]["udid"])
')"
fi

mkdir -p TestResults
result_bundle="TestResults/iOS-$(date +%Y%m%d-%H%M%S)-$$.xcresult"
xcodebuild test \
  -project Example/DynamicIslandToastExample.xcodeproj \
  -scheme DynamicIslandToastExample \
  -configuration Debug \
  -destination "platform=iOS Simulator,id=$simulator_id" \
  -derivedDataPath Example/DerivedData \
  -resultBundlePath "$result_bundle" \
  CODE_SIGNING_ALLOWED=NO
