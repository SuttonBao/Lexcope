#!/bin/bash
set -euo pipefail
TASK_BUILD_DIR="${TMPDIR:-/tmp}/lexcope-build/arm64-apple-macosx/debug"
if [[ "$(uname -m)" != arm64 ]]; then
  TASK_BUILD_DIR="${TMPDIR:-/tmp}/lexcope-build/x86_64-apple-macosx/debug"
fi
export CLANG_MODULE_CACHE_PATH="${TMPDIR:-/tmp}/lexcope-clang-cache"
TASK_TARGET="$(uname -m)-apple-macosx14.0"
swiftc -typecheck -parse-as-library -target "$TASK_TARGET" -I "$TASK_BUILD_DIR/Modules" App/*.swift
swiftc -parse-as-library -target "$TASK_TARGET" -I "$TASK_BUILD_DIR/Modules" \
  App/AppModel.swift IntegrationTests/AppModelHarness.swift "$TASK_BUILD_DIR"/LexcopeCore.build/*.o \
  -o "${TMPDIR:-/tmp}/lexcope-model-integration"
"${TMPDIR:-/tmp}/lexcope-model-integration"
