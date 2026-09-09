#!/usr/bin/env bash
set -euo pipefail

cd ../producer
evidence="$RUNNER_TEMP/validation"
printf 'phase\telapsed_ms\n' > "$evidence/timings.tsv"
printf 'RUSTFLAGS=%s\nCARGO_ENCODED_RUSTFLAGS=%s\nCARGO_INCREMENTAL=%s\n' \
  "${RUSTFLAGS:-}" "${CARGO_ENCODED_RUSTFLAGS:-}" "${CARGO_INCREMENTAL:-}" \
  > "$evidence/compiler-environment.txt"

measure() {
  local phase="$1"
  shift
  local started
  started="$(date +%s%3N)"
  "$@"
  printf '%s\t%s\n' "$phase" "$(( $(date +%s%3N) - started ))" >> "$evidence/timings.tsv"
  if [[ -n "${RUSTC_WRAPPER:-}" ]]; then
    "$RUSTC_WRAPPER" --show-stats --stats-format json > "$evidence/$phase-sccache.json"
  fi
}

measure release cargo build --release -p conary-core \
  --features native-alpm-oracle \
  --bin conary-alpm-oracle --bin conary-alpm-resolution-oracle
sha256sum target/release/conary-alpm-oracle target/release/conary-alpm-resolution-oracle \
  > "$evidence/producer-binaries.sha256"
target/release/conary-alpm-oracle --help > "$evidence/package-help.txt"
target/release/conary-alpm-resolution-oracle --help > "$evidence/resolution-help.txt"
measure parity cargo test -p conary-core --features native-alpm-oracle \
  repository::catalog::parity::alpm --verbose
measure clippy cargo clippy -p conary-core --features native-alpm-oracle \
  --lib --bin conary-alpm-oracle --bin conary-alpm-resolution-oracle -- -D warnings
[[ -z "$(git status --porcelain)" ]]
