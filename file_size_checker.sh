#!/usr/bin/env sh
set -eu

# Get inputs (with defaults for local testing)
MAX_FILE_SIZE_KB="${MAX_FILE_SIZE_KB:-20}"
BASE_SHA="${BASE_SHA:-}"
HEAD_SHA="${HEAD_SHA:-}"
#FAIL_ON_LARGE_FILES="${FAIL_ON_LARGE_FILES:-false}"
#EXCLUDE_PATTERNS="${EXCLUDE_PATTERNS:-}"
#INCLUDE_PATTERNS="${INCLUDE_PATTERNS:-}"
#CHECK_ALL_COMMITS="${CHECK_ALL_COMMITS:-}"

# Fall back to local commits when inputs are omitted.
if [ -z "$HEAD_SHA" ]; then
  HEAD_SHA=$(git rev-parse HEAD 2>/dev/null || true)
  if [ -z "$HEAD_SHA" ]; then
    echo "::error::Unable to determine HEAD SHA from the current repository state."
    exit 1
  fi
fi

if [ -z "$BASE_SHA" ]; then
  BASE_SHA=$(git rev-parse HEAD~1 2>/dev/null || true)
  if [ -z "$BASE_SHA" ]; then
    BASE_SHA="$HEAD_SHA"
    echo "::notice::Single-commit repository detected; using HEAD as both base and head for size checks."
  fi
fi


if ! [ "$MAX_FILE_SIZE_KB" -gt 0 ] 2>/dev/null; then
  echo "::error::Invalid max-file-size-kb value: '$MAX_FILE_SIZE_KB'. Must be a positive number."
  exit 1
fi

MAX_SIZE_BYTES=$((MAX_FILE_SIZE_KB * 1024))
MAX_SIZE_HUMAN="${MAX_FILE_SIZE_KB}KB"

# Export the readable label for the GH comment
echo "max_size_human=${MAX_SIZE_HUMAN}" >> "$GITHUB_OUTPUT"

# 2. Get the list of newly added files
echo "Finding newly added files in range: $BASE_SHA..$HEAD_SHA"

NEW_FILES=$(git diff --name-only --diff-filter=A "$BASE_SHA" "$HEAD_SHA")

EXIT_CODE=0
VIOLATIONS_MESSAGE="" # String to build the markdown list of failed files

echo "--- Checking new files added against ${MAX_SIZE_HUMAN} limit ---"

if [ -z "$NEW_FILES" ]; then
  echo "No new files detected in this PR. Check vacuously passes."
else
  for file in $NEW_FILES; do
    if [ ! -f "$file" ]; then
      echo "::warning file=$file::File not found in workspace. Skipping size check for: $file"
      continue
    fi

    FILE_SIZE=$(stat -c %s "$file" 2>/dev/null) || {
      echo "::warning file=$file::Unable to get file size (stat failed). Skipping: $file"
      continue
    }

    echo "--- NEW FILE:$file SIZE: $FILE_SIZE ---"
    if [ "$FILE_SIZE" -gt "$MAX_SIZE_BYTES" ]; then
      # Calculate human-readable sizes for error output
      FILE_SIZE_KB=$((FILE_SIZE / 1024))

      # Format the violation for the GitHub comment
      VIOLATION_LINE="- **\`$file\`**: **${FILE_SIZE_KB} KB** (Max allowed: ${MAX_SIZE_HUMAN})"

      echo "::error file=$file::File size check failed: $file is too large."
      echo "$VIOLATION_LINE"

      # Append to the violations message
      VIOLATIONS_MESSAGE="${VIOLATIONS_MESSAGE}\n${VIOLATION_LINE}"
      EXIT_CODE=1
    else
      echo "  - Passed: $file"
    fi
  done
fi

# Set the violations list as a multiline output, which can be consumed by the next step
if [ "$EXIT_CODE" -ne 0 ]; then
    echo "violations_list<<EOF" >> "$GITHUB_OUTPUT"
    echo "$VIOLATIONS_MESSAGE" >> "$GITHUB_OUTPUT"
    echo "EOF" >> "$GITHUB_OUTPUT"
fi


if [ "$EXIT_CODE" -ne 0 ]; then
  echo "--- FAILURE: One or more new files exceed the maximum size of ${MAX_SIZE_HUMAN}. ---"
  exit 1
fi
echo "--- SUCCESS: All new files are within the maximum size limit. ---"
