#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
CONFIG_BACKUP="$(mktemp)"
cp project.godot "$CONFIG_BACKUP"
cleanup() {
  cp "$CONFIG_BACKUP" project.godot
  rm -f "$CONFIG_BACKUP"
}
trap cleanup EXIT INT TERM

if grep -q '^RegressionDriver=' project.godot; then
  echo "RegressionDriver is already registered in project.godot; refusing to alter an existing test setup." >&2
  exit 2
fi
sed -i '/^AudioManager=/a RegressionDriver="*res://tests/full_path_regression.gd"' project.godot
godot --headless --path "$ROOT"
