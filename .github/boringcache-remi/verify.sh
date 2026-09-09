#!/usr/bin/env bash
set -euo pipefail

cd "$GITHUB_WORKSPACE/producer"
evidence="$RUNNER_TEMP/remi-comparison"
[[ "$(git rev-parse HEAD)" == "$CONARY_GIT_COMMIT" ]]
[[ -z "$(git status --porcelain --untracked-files=all)" ]]
[[ -x target/release/remi ]]
target/release/remi --version | tee "$evidence/remi-version.txt"
[[ "$(cat "$evidence/remi-version.txt")" == "remi $(sed -n 's/^version = "\([^"]*\)"/\1/p' Cargo.toml)" ]]
target/release/remi --help > "$evidence/remi-help.txt"
sha256sum target/release/remi > "$evidence/remi.sha256"
file target/release/remi > "$evidence/remi-file.txt"
ldd target/release/remi > "$evidence/remi-libraries.txt"
while IFS= read -r library; do
  if [[ "$library" == *'not found'* ]]; then
    echo 'Remi has unresolved runtime libraries' >&2
    exit 1
  fi
done < "$evidence/remi-libraries.txt"
[[ -s target/cargo-timings/cargo-timing.html ]]
cp target/cargo-timings/cargo-timing.html "$evidence/cargo-timing.html"
[[ -z "$(git status --porcelain --untracked-files=all)" ]]
