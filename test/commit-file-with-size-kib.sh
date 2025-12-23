#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 3 ]; then
  echo "Usage: $0 <file-path> <size-in-kibibytes> <commit-message>" >&2
  exit 2
fi

FILE_PATH=$1
SIZE_KIB=$2
shift 2
COMMIT_MESSAGE="$*"

if ! [[ $SIZE_KIB =~ ^[0-9]+$ ]] || [ "$SIZE_KIB" -le 0 ]; then
  echo "Size must be a positive integer (KiB). Received: $SIZE_KIB" >&2
  exit 2
fi

FILE_DIR=$(dirname "$FILE_PATH")
mkdir -p "$FILE_DIR"

dd if=/dev/zero of="$FILE_PATH" bs=1K count="$SIZE_KIB" status=none

git add "$FILE_PATH"
git commit -m "$COMMIT_MESSAGE"

HEAD_SHA=$(git rev-parse HEAD)

if [ -n "${GITHUB_ENV:-}" ]; then
  echo "HEAD_SHA=$HEAD_SHA" >> "$GITHUB_ENV"
else
  echo "HEAD_SHA=$HEAD_SHA"
fi

echo "Committed '$FILE_PATH' (${SIZE_KIB}KiB) with HEAD $HEAD_SHA"
