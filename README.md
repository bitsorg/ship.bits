# ship.bits

Policy layer and recipes for building **FairShip** (the SHiP experiment software) with [`bits`](../bits). It is a thin overlay on [`stacks.bits`](../stacks.bits), the shared base every community builds on: the build environment, the compiler/build-type profiles and the ~1100-recipe [`lcg.bits`](../lcg.bits) pool all come from there. This repository adds only the SHiP CVMFS namespace, the FairRoot/FairShip stack, and the few externals SHiP must build differently from LCG.

Anything not listed under [Recipes](#recipes) comes from `lcg.bits` and hashes like the same package built by any other group on the same base (a group that sets its own `env:` or `package_family`, as LHCb currently does, is not on the same base), so it is **reused from the store** instead of rebuilt.

---

## Provider chain

```
ship.bits  ──requires──▶  stacks.bits  ──requires──▶  lcg.bits
  defaults-ship.sh          defaults-release.sh          ROOT, Geant4, pythia8,
  FairRoot, FairShip, …     gcc13/14/15, clang, dbg,      evtgen, acts, lhapdf, …
                            cuda, dev3/dev4
```

`bits` clones `stacks.bits` and `lcg.bits` on demand (repository-provider packages) into `sw/REPOS/` and adds them to `BITS_PATH`. Recipes in `ship.bits` come first on the path, so a recipe here **replaces** the `lcg.bits` one of the same name for the whole SHiP build.

---

## The `defaults-ship.sh` Overlay

Composed with `--defaults ship[::gcc15]`.

- `requires: stacks.bits` — the shared base.
- `variables: release: "main"` plus `overrides: lcg.bits`/`stacks.bits: tag: "%(release)s"` — both providers follow the release; `main` is only the default (see [Releases](#releases)). Identical in every stacks-based overlay.
- `overrides: "ROOT:osx"` — ROOT v6.40.00 on macOS only, for Apple-clang/Xcode; Linux keeps the recipe default.
- `system:` — the CVMFS namespace and store policy. Never hashed, so it never affects reuse.

| `system:` field | Value |
|---|---|
| `prefix` | `/cvmfs/bits.cern.ch/ship` — must match `cvmfs_prefix` in bits-console `communities/SHiP/ui-config.yaml`, or a build refuses to publish |
| `cvmfs_user_prefix` | `{prefix}/user` — per-user publishes go to `<user_prefix>/<login>` |
| `cvmfs_packages_template` | `{prefix}/{arch}/Packages/{pkg}/{tag}` |
| `cvmfs_modules_template` | `{prefix}/{arch}/Modules/modulefiles/{pkg}` |
| `cvmfs_shared_path_template` | `{prefix}/noarch/{pkg}/{tag}` |
| `cvmfs_releases_template`, `cvmfs_views_template` | empty — no release views (ALICE-style) |
| `remote_store`, `certify_group`, `manifests_remote` | S3 store, certification group and manifests repo for SHiP builds |

As in ALICE, a package lands once at `…/ship/<arch>/Packages/<pkg>/<version>-<revision>`, where `<arch>` is the build arch (e.g. `x86_64-el9-gcc15-opt`), whatever release it was built for; a package already there is not published again.

The overlay deliberately has **no `env:` and no `disable:`**: both are hashed and would make every SHiP package differ from the shared stacks.

---

## Recipes

SHiP's own stack:

| Package | Version | Notes |
|---|---|---|
| `FairShip` | 26.06 | top of the stack |
| `FairRoot` | v19.0.1 | |
| `FairLogger` | v2.3.2 | |
| `FairCMakeModules` | v1.0.0 | |
| `GEANT3` | v4-5 | |
| `ROOTEGPythia6` | pinned commit | |
| `ninja-fortran` | Kitware Fortran fork | build tool for `pythia6` |
| `termcap` | 1.0 | system check (`termcap.h`) |

Externals that **replace** the `lcg.bits` recipe, because SHiP needs a different build:

| Package | SHiP | `lcg.bits` | Why |
|---|---|---|---|
| `ROOT` | v6.38.00, with Pythia8/TPythia8 | v6.40.02 | FairShip uses TPythia8 |
| `pythia6` | v6.4.28-snd | 429.2 | SHiP/SND-LHC sources with the ROOT/TPythia6 glue |
| `GENIE` | R-3_06_02 | 2.12.6 | FairShip needs GENIE 3 |

Each replacement changes the hash of that package and of everything above it in the SHiP build, so those are rebuilt for SHiP; everything below them is still reused. `lhapdf` is taken from `lcg.bits`.

---

## Releases

The single `release` variable names the `lcg.bits` (and `stacks.bits`) branch to build against. SHiP's CVMFS paths have no release level: packages are published once per build arch whatever the release. `bits` resolves it, highest precedence first:

**Pass the release on the command line** (`--set release=LCG_110`); `main` is only the default. Every stacks-based group (atlas, lhcb, key4hep, ship) follows this rule, because a `--set` value is also exported into the build environment and enters every package hash: a release chosen any other way (a `release:` in a profile, or the checkout's branch name) hashes differently, and nothing the other groups built would be reused. Reuse also needs the same `lcg.bits` and `stacks.bits` commits and the same compiler/build-type profiles.

The effective release must exist as an `lcg.bits` and a `stacks.bits` branch.

---

## Command-Line Usage

```bash
bits deps  FairShip --defaults ship::gcc15                         # inspect the tree
bits build FairShip --defaults ship::gcc15                         # main line
bits build FairShip --defaults ship::gcc15 --set release=LCG_110   # on LCG_110
bits build FairShip --defaults ship::gcc15::testbed                # publish to the testbed root
```

The `testbed` overlay (from [`testbed.bits`](../testbed.bits), which must be on `BITS_PATH`; always last in the chain) replaces only the CVMFS root and user prefix; the layout above is kept.

Explore a local build with `bitsenv`:

```bash
bitsenv q FairShip
bitsenv enter FairShip/26.06
```

`bits cvmfs-path -c . --defaults ship::gcc15 --admin --package <pkg> --version <v> --platform <p>` prints where a package would be published, without building.

---

## Files Overview

| File | Role |
|---|---|
| `defaults-ship.sh` | SHiP overlay: `stacks.bits` base, release tracking, CVMFS namespace, store policy, macOS ROOT pin |
| `fairship.sh`, `fairroot.sh`, `fairlogger.sh`, `faircmakemodules.sh`, `geant3.sh`, `rootegpythia6.sh` | the SHiP stack |
| `root.sh`, `pythia6.sh`, `genie.sh` | SHiP builds of externals that replace the `lcg.bits` recipes |
| `ninja-fortran.sh`, `termcap.sh` | build tool and system check |
