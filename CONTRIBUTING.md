# Contributing

Thanks for considering contributing to mobile_scanner!

## Pull requests

* PR titles must follow [Conventional Commits](https://www.conventionalcommits.org/) (e.g. `feat: ...`, `fix: ...`, `chore: ...`) — this is enforced by CI and is what drives the automated changelog and release process below.
* Open feature/fix PRs against `develop`.
* Individual commits don't have to follow Conventional Commits, but it helps: if every commit in your PR is properly typed, we can merge with a real merge commit and keep your full history. If not, we'll squash the PR into a single commit (using the PR title) instead. Either way the changelog/version stay correct — this only affects how much of your history is preserved.

## Release process

Releases are automated with [Release Please](https://github.com/googleapis/release-please), driven by the Conventional Commit PR titles above.

* **Normal releases** happen on `develop`. Release Please keeps a `chore(main): release X.Y.Z` PR up to date with the version bump (`pubspec.yaml`) and changelog. Merging it tags the release, publishes a GitHub Release, and triggers publishing to pub.dev. That release is then automatically promoted to `master`, so `master` always reflects the latest published version.
* **Hotfixes** are branched from `master` instead of `develop`, so they don't pull in unreleased work. A hotfix PR into `master` goes through the same Release Please flow (its own release PR, tag, GitHub Release, pub.dev publish), and afterwards a PR to merge the hotfix back into `develop` is opened automatically — this one needs a manual merge, since the changelog/version files can conflict with unreleased changes on `develop`.
