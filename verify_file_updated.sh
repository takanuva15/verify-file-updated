#!/bin/bash

#function obtained from https://stackoverflow.com/a/2990533
echoerr() { printf "%s\n" "$*" >&2; }

#credit to https://stackoverflow.com/a/61922402 for providing a starting point for this script

# Fetch all changed files in this PR (including paged responses) and verify
# the user-specified file is among the changes.
page=1
per_page=100

while true; do
  pr_files_json=$(curl -s -u "$OWNER":"$GITHUB_TOKEN" -H "Accept: application/vnd.github.v3+json" \
    "$PR_API_URL/files?per_page=$per_page&page=$page")

  page_files=$(jq -r '.[] | .filename' <<<"$pr_files_json")

  # Stop when the API returns no files for the next page.
  if [[ -z "$page_files" ]]; then
    break
  fi

  # Return early as soon as the required file is found on any page.
  if grep -Fxq "$FILENAME_TO_CHECK" <<<"$page_files"; then
    echo "Detected '${FILENAME_TO_CHECK}' among the changed files in this PR. Verification succeeded!"
    exit 0
  fi

  page=$((page + 1))
done

echoerr "Could not find '${FILENAME_TO_CHECK}' among the changed files in this PR! '${FILENAME_TO_CHECK}' must " \
  "be updated within the PR to pass this check."
exit 1
