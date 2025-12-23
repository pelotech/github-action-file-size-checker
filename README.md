# File Size Checker Action

File Size Checker ensures every newly added file in a pull request stays below a size threshold that you define. Drop it into any workflow to keep oversized binaries or assets from entering your repository.

## Quick Start

```yaml
name: Check File Sizes

on:
  pull_request:
    branches:
      - main

jobs:
  check-size:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Fail if new files are committed over 25KiB
        id: size_check
        uses: pelotech/github-action-file-size-checker@main
        with:
          max_file_size_kib: '25'
```
note: make sure to use latest released version or pin to a sha

## Inputs

| Name | Required | Default | Description |
| --- | --- | --- | --- |
| `max_file_size_kib` | Yes | `20` | Maximum filesize, in kilobytes, that any newly added file may have. |
| `base_sha` | Yes | `${{ github.event.pull_request.base.sha }}` | Commit SHA used as the lower bound of the diff. Override this if you need to compare against a custom baseline (for example, on push workflows). |
| `head_sha` | Yes | `${{ github.event.pull_request.head.sha }}` | Commit SHA used as the upper bound of the diff. Override when running outside of a pull request. |

> **Tip:** When the workflow runs inside a pull request, you can omit `base_sha` and `head_sha` because the defaults resolve automatically.

## Outputs

- `violations_list`: Markdown-formatted bullet list describing every new file above the size cap; empty string when no violations occur.
- `max_size_human`: Human-readable representation of the chosen size limit (for example, 25KiB).

## Usage Tips
- Ensure the workflow fetches enough history (actions/checkout with fetch-depth: 0) so both SHAs exist locally.
- The action only inspects files that are newly added between `base_sha` and `head_sha`. Updates to existing files are ignored by design.
- If you run the action on push or scheduled workflows, provide valid `base_sha`/`head_sha` inputs to control the diff range.
- Custom comparisons: Supply explicit `base_sha` and `head_sha` to compare across release branches or long-lived feature branches.
- You can use the outputs with other actions to enhance the workflow when there are violations. For example, to post a PR comment when there are violations:
  ```yaml
  - name: Post comment when violations exist
      if: steps.size_check.outputs.violations_list != ''
      uses: peter-evans/create-or-update-comment@v5
      with:
        issue-number: ${{ github.event.pull_request.number }}
        body: |
          ## New File Size Violation Detected

          The following files exceed **${{ steps.size_check.outputs.max_size_human }}**:

          ${{ steps.size_check.outputs.violations_list }}

          Please shrink or remove the files above the limit.
  ```
