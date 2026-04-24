#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_PATH="$ROOT_DIR/dist/Debug/tex.app"

if [[ ! -d "$APP_PATH" ]]; then
  echo "Missing app bundle at $APP_PATH"
  echo "Build it first with: xcodebuild -project tex.xcodeproj -scheme tex -configuration Debug build"
  exit 1
fi

open -n "$APP_PATH"
