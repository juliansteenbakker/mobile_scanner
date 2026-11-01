#!/usr/bin/env bash
# Appends a contributors section to the GitHub release for the given tag.
#
# release-please writes the release notes from commit messages, which never
# name the authors. GitHub's generated notes do, so the authors are taken from
# those. Only the GitHub release is changed; CHANGELOG.md stays as it is.
#
# Usage: thank-contributors.sh <tag>
# Requires GH_TOKEN and GITHUB_REPOSITORY. Set DRY_RUN=1 to print the
# section instead of editing the release.
set -euo pipefail

tag="$1"
repo="${GITHUB_REPOSITORY}"
owner="${repo%%/*}"
heading="### Contributors"

body="$(gh release view "$tag" --repo "$repo" --json body --jq .body)"

if grep -qxF "$heading" <<<"$body"; then
  echo "The release for $tag already thanks its contributors."
  exit 0
fi

notes="$(gh api "repos/$repo/releases/generate-notes" -f tag_name="$tag" --jq .body)"

# Every PR line reads "* <title> by @<author> in <url>". Bots and the
# maintainer who cuts the release are left out.
contributors="$(
  grep -oE ' by @[A-Za-z0-9-]+(\[bot\])? in ' <<<"$notes" |
    sed -E 's/^ by (@[^ ]+) in $/\1/' |
    grep -vF '[bot]' |
    grep -vxF "@$owner" |
    awk '!seen[$0]++' ||
    true
)"

if [[ -z "$contributors" ]]; then
  echo "No contributors to thank for $tag."
  exit 0
fi

thanks="Thanks to $(paste -sd ',' - <<<"$contributors" | sed 's/,/, /g') for contributing to this release."

# GitHub's own list of first-time contributors, kept as is.
new_contributors="$(
  awk '/^## New Contributors/ { found = 1; next }
    /^(## |\*\*Full Changelog)/ { found = 0 }
    found && /^\* /' <<<"$notes"
)"

section="$heading"$'\n\n'"$thanks"
if [[ -n "$new_contributors" ]]; then
  section+=$'\n\n'"New contributors:"$'\n\n'"$new_contributors"
fi

if [[ -n "${DRY_RUN:-}" ]]; then
  printf '%s\n' "$section"
  exit 0
fi

notes_file="$(mktemp)"
printf '%s\n\n%s\n' "$body" "$section" >"$notes_file"
gh release edit "$tag" --repo "$repo" --notes-file "$notes_file"
