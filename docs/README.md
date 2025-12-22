# github-action-file-size-checker
github action to check file sizes that are committed to the repo


# Usage

post to the PR after

```yaml
  - name: Post Comment on Size Violation
    uses: peter-evans/create-or-update-comment@v5
    if: always() && steps.size_check.outputs.violations_list != ''
    with:
      issue-number: ${{ github.event.pull_request.number }}
      body: |
        ## New File Size Violation Detected

        The following files added in this Pull Request exceed the maximum allowed size of **${{ steps.size_check.outputs.max_size_human }}**:

        ${{ steps.size_check.outputs.violations_list }}

        Please reduce the size of or remove these files. The CI check will fail until these files are below the limit.

      reaction-type: 'confused'
```
