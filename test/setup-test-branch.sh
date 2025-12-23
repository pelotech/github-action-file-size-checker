#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <branch-name>" >&2
  exit 2
fi

BRANCH_NAME=$1
GIT_USER_NAME=${GIT_USER_NAME:-integration-test}
GIT_USER_EMAIL=${GIT_USER_EMAIL:-integration-test@example.com}

git config user.name "$GIT_USER_NAME"
git config user.email "$GIT_USER_EMAIL"

# Create or reset the target branch for the test run.
git switch -C "$BRANCH_NAME"

BASE_SHA=$(git rev-parse HEAD)

if [ -n "${GITHUB_ENV:-}" ]; then
  {
    echo "BASE_SHA=$BASE_SHA"
  } >> "$GITHUB_ENV"
else
  echo "BASE_SHA=$BASE_SHA"
fi

echo "Prepared test branch '$BRANCH_NAME' at $BASE_SHA"
