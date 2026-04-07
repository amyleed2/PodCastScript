#!/bin/bash
set -e

echo "[hook] Running format/lint checks..."

if command -v swiftformat >/dev/null 2>&1; then
  swiftformat .
fi

if command -v swiftlint >/dev/null 2>&1; then
  swiftlint
fi

echo "[hook] Lint/format done."