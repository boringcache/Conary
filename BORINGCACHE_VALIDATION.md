# BoringCache validation for Conary's Arch native producers

This fork validates the release compilation of `conary-alpm-oracle` and `conary-alpm-resolution-oracle`, the 35 selected ALPM parity tests, and the existing clippy command. It does not run Conary's complete CI or its protected production export, survey, attestation and multi-distribution assembly. Upstream authorization and acceptance conditions remain unchanged.

The jobs use the upstream pinned Arch image and August 2, 2026 package archive, Rust 1.98.0 and libalpm 16.0.1. Each runs from a clean checkout of the original upstream commit with no target directory. BoringCache One v1.21.0 is pinned to `90111526eb218a7f1e119ac2b29f765bd4d82734`, uses GitHub OIDC and configures native sccache 0.17.0. Only compiler outputs are stored in BoringCache; finished targets and Cargo dependency downloads are not restored. The release profile, features, tests and lint rules are preserved. Incremental compilation is disabled for native sccache on both comparison sides.

## Results

| Run / job | Release build | ALPM test command | Clippy | Full job | Result |
| --- | ---: | ---: | ---: | ---: | --- |
| [Uncached](https://github.com/boringcache/Conary/actions/runs/34315921920/job/102352005562) | 585.647 s | 257.469 s | 89.429 s | 1,007 s | Passed |
| [BoringCache cold commands](https://github.com/boringcache/Conary/actions/runs/34316281271/job/102355369501) | 496.794 s | 276.355 s | 90.070 s | Excluded | Commands passed; cancelled during post-step |
| [BoringCache warm](https://github.com/boringcache/Conary/actions/runs/34319217643/job/102361945290) | 84.493 s | 146.022 s | 51.518 s | 387 s | Passed |
| [Source change 1](https://github.com/boringcache/Conary/actions/runs/34319901476/job/102364004626) | 92.009 s | 160.194 s | 50.916 s | 400 s | Passed |
| [Source change 2](https://github.com/boringcache/Conary/actions/runs/34320530052/job/102365921685) | 408.213 s | 182.226 s | 53.384 s | 721 s | Passed |
| [Source change 3](https://github.com/boringcache/Conary/actions/runs/34321556146/job/102369125604) | 88.000 s | 154.084 s | 53.155 s | 383 s | Passed |
| [Source change 4](https://github.com/boringcache/Conary/actions/runs/34322138357/job/102370961589) | 89.208 s | 157.655 s | 50.445 s | 389 s | Passed |
| [Source change 5](https://github.com/boringcache/Conary/actions/runs/34322700879/job/102372759242) | 94.427 s | 164.291 s | 52.017 s | 396 s | Passed |

The warm selected job took 6m27s, compared with 16m47s uncached. Its release command took 84.493 seconds, compared with 585.647 seconds. The release timing excludes cache setup; the warm One setup took 36 seconds. Full job duration includes setup and cleanup but excludes GitHub scheduling delay.

These are individual samples. The initial uncached, cold and warm jobs did not retain CPU identity. Source change 2 used an Intel Xeon 8370C; the other recorded CPU models appear below. Its longer release time cannot be attributed only to the changed source. The cold job did not finish successfully: its producer commands passed, but it was cancelled during prolonged process-exit polling. Its full job duration is excluded. The initial uncached and cold jobs did not use Docker `--init`; later jobs do and complete their post-steps normally. A [read-only paired diagnostic](https://github.com/boringcache/Conary/actions/runs/34318918409) supports process reaping as an explanation, but did not directly establish the original proxy's process state after SIGTERM.

## Five original source changes

The sequence starts at `5dc83cc284d0a565f5d5c94e466cc6eeae3ddad0` and advances one captured first-parent change at a time to `2fcae09fc270c36d4815e3da69c732c67463bb9e`.

| Change / original source | Selected run | Rust hits / misses | New writes | CPU model |
| --- | --- | ---: | ---: | --- |
| 1 / [`f71f9b13`](https://github.com/FieldmouseWorks/Conary/commit/f71f9b13336dcf3dcc157709ed80c40bac7918d7) | [34319901476](https://github.com/boringcache/Conary/actions/runs/34319901476) | 1,546 / 0 | 0 | AMD EPYC 7763 |
| 2 / [`9fe7f44a`](https://github.com/FieldmouseWorks/Conary/commit/9fe7f44a104ca0044a4af1e3e5bf9f30f68b99af) | [34320530052](https://github.com/boringcache/Conary/actions/runs/34320530052) | 1,544 / 2 | 2 | Intel Xeon 8370C |
| 3 / [`9a875f28`](https://github.com/FieldmouseWorks/Conary/commit/9a875f28b9a173117ad4a32178b29121d22b85df) | [34321556146](https://github.com/boringcache/Conary/actions/runs/34321556146) | 1,546 / 0 | 0 | AMD EPYC 7763 |
| 4 / [`d705edfd`](https://github.com/FieldmouseWorks/Conary/commit/d705edfd91f6eb453244af3be6b6911a0a884def) | [34322138357](https://github.com/boringcache/Conary/actions/runs/34322138357) | 1,546 / 0 | 0 | AMD EPYC 7763 |
| 5 / [`2fcae09f`](https://github.com/FieldmouseWorks/Conary/commit/2fcae09fc270c36d4815e3da69c732c67463bb9e) | [34322700879](https://github.com/boringcache/Conary/actions/runs/34322700879) | 1,546 / 0 | 0 | AMD EPYC 7763 |

The second change modifies CCS verification in the measured core crate. The other four do not modify either measured workspace package. All oracle binary digests remained identical to the uncached baseline, including after the CCS change; this is not evidence of five changes to ALPM behavior. All five selected jobs passed the same ALPM tests and clippy.

Native cache read/write errors, cache error maps and timeouts were zero. The separate native `compile_fails` counter was nine even when the selected commands passed; its cause was not established. Rust hit counts cover cacheable requests and do not weight the time spent on individual compilations.

After all five changes, the signed-in [cache inventory](https://boringcache.com/boringcache/conary-onboarding/cache) displayed 2,406 live keys / 1.2 GB, compared with the original 2,404-key / 1.01 GB seed. Current version 6 referenced a working set of 2,404 keys / 1.01 GB. Only the two changed outputs added retained keys; the cache-side UI reported 193 MB written for them. These rounded observations distinguish the current working set from retained history. They do not establish exact new physical bytes, deduplication savings or an eviction outcome.

## Workflows and excluded runs

[OIDC enrollment](https://github.com/boringcache/Conary/actions/runs/34315771793) passed. An [earlier enrollment attempt](https://github.com/boringcache/Conary/actions/runs/34315475915) was cancelled after delayed live approval instructions; the delay's cause was not established. The [first cold setup](https://github.com/boringcache/Conary/actions/runs/34315921920/job/102352005470) lacked sccache and failed before compilation. A [pending correction](https://github.com/boringcache/Conary/actions/runs/34316162197) was cancelled before the explicit producer command step was added. These are excluded from the performance comparison. An [unintended repeat](https://github.com/boringcache/Conary/actions/runs/34321492726) resolved the preceding validation commit after the third source push and was cancelled before cache setup or compilation. Its replacement used the correct immutable commit.

The workflow definitions are [initial/warm validation](.github/workflows/boringcache-validation.yml), [sequential source validation](.github/workflows/boringcache-rolling.yml), and [OIDC connection](.github/workflows/boringcache-connect.yml). Native statistics, package/compiler identity, source commits, binary digests and phase timings are retained in each run's artifact.

Repeating the `fresh` dispatch does not empty this populated cache. A new cold comparison requires a separate empty cache identity and an empty-storage observation before its writer starts. No upstream pull request, issue comment, deployment or image publication was made.
