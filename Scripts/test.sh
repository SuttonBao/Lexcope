#!/bin/bash
set -euo pipefail
export CLANG_MODULE_CACHE_PATH="${TMPDIR:-/tmp}/lexcope-clang-cache"
export SWIFT_MODULECACHE_PATH="${TMPDIR:-/tmp}/lexcope-swift-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$SWIFT_MODULECACHE_PATH"
TASK_SWIFT_FLAGS=()
TASK_DEVELOPER_PATH="$(xcode-select -p)"
if [[ "$TASK_DEVELOPER_PATH" == */CommandLineTools ]]; then
  TASK_FRAMEWORKS="$TASK_DEVELOPER_PATH/Library/Developer/Frameworks"
  TASK_SWIFT_FLAGS=(-Xswiftc -F -Xswiftc "$TASK_FRAMEWORKS" -Xlinker -rpath -Xlinker "$TASK_FRAMEWORKS" -Xlinker -rpath -Xlinker "$TASK_DEVELOPER_PATH/Library/Developer/usr/lib")
fi
swift test --scratch-path "${TMPDIR:-/tmp}/lexcope-build" --cache-path "${TMPDIR:-/tmp}/lexcope-cache" --disable-sandbox "${TASK_SWIFT_FLAGS[@]}"
