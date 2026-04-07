#!/bin/bash
set -e

echo "[hook] Running test/build checks..."

if [ -f "Package.swift" ]; then
  swift test
else
  echo "[hook] No Package.swift found. Skipping swift test."
fi