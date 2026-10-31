# ship.bits

Recipes and defaults for building **FairShip**, the SHiP experiment software, with
[bits](https://github.com/bitsorg/bits). The repository contains the SHiP stack
(FairShip, FairRoot, FairLogger, FairCMakeModules, GEANT3, ROOTEGPythia6), SHiP builds
of three externals (ROOT, pythia6, GENIE), and the SHiP CVMFS and store settings in
`defaults-ship.sh`. All other packages (Geant4, pythia8, EvtGen, ACTS, LHAPDF, ...) come
from the [lcg.bits](https://github.com/bitsorg/lcg.bits) recipe pool. `defaults-ship.sh`
requires [stacks.bits](https://github.com/bitsorg/stacks.bits), which provides the shared
`release` base and the compiler and build-type profiles, and `stacks.bits` in turn
requires `lcg.bits`. bits fetches both automatically through the
[bits-providers](https://github.com/bitsorg/bits-providers) registry.

The SHiP stack recipes are bits ports of the aliBuild recipes in
[ShipSoft/shipdist](https://github.com/ShipSoft/shipdist), at the same package versions.
Unlike shipdist, ship.bits does not build its own copy of every external: packages taken
from `lcg.bits` get the same hashes as in the other stacks and are reused from the
binary store instead of rebuilt.

## Prerequisites

- bits, and one of two setups (see [Installation &
  Prerequisites](https://github.com/bitsorg/bits/blob/main/docs/USERGUIDE.md#2-installation--prerequisites)
  in the bits user guide; `bits doctor` checks the machine):
  - docker or rootless podman, to build in the platform's builder image with `--docker`
    (recommended, and the only way to reuse what the SHiP CI built);
  - or the system packages listed in [Building
    natively](https://github.com/bitsorg/bits/blob/main/docs/USERGUIDE.md#building-natively-what-to-install),
    to build with this machine's compilers and libraries.
- A platform the SHiP CI builds, so that its binaries are reused: `x86_64-el8`,
  `x86_64-el9`, `x86_64-el10`, `aarch64-el9`, `x86_64-ubuntu2204`, `x86_64-ubuntu2404` and
  `x86_64-ubuntu2604`. Pass it as `--architecture`: by itself bits names a machine after
  its OS (an EL9 machine `slc9_x86-64`), which is not one of them. See [Finding a platform
  with pre-built
  binaries](https://github.com/bitsorg/bits/blob/main/docs/USERGUIDE.md#finding-a-platform-with-pre-built-binaries).
- On macOS (a native build), `defaults-ship.sh` switches ROOT to v6.40.00 for Apple clang
  and Xcode.
- Read access to the SHiP binary store set in `defaults-ship.sh`
  (`https://s3.cern.ch/swift/v1/lcgapp-bits-testing`). bits fetches prebuilt packages from
  it by default.

## Getting started

```bash
bits init ship.bits && cd ship.bits     # or: git clone https://github.com/bitsorg/ship.bits
bits use --architecture x86_64-el9 --defaults ship::gcc15::opt  # on macOS: without --architecture
bits use build --docker --set release=LCG_110  # on macOS: without --docker
bits build --dry-run FairShip
bits build FairShip
bits enter FairShip/latest
```

The `bits use` profile stores the settings in this checkout: the platform and the defaults
for every command, so `bits q` and `bits enter` find this build among others in the work
directory, the rest for `bits build`; options given on the command line still win. The
build architecture is `x86_64-el9-gcc15-opt`. `--docker` builds in the platform's builder
image; on a machine of the same platform `bits enter` then works here. Without it, bits
builds with this machine's compilers and system packages, and reuses nothing the CI built.
Check the machine with `bits doctor`. To build elsewhere, `export
BITS_WORK_DIR=/path/to/sw`. See
[Configuration](https://github.com/bitsorg/bits/blob/main/docs/USERGUIDE.md#4-configuration)
in the bits user guide. Leave out `--set release=...` to build against the `main` branches
of `lcg.bits` and `stacks.bits`.

## Notes for SHiP users

- **Choosing defaults.** Name the group overlay (`ship`), then one compiler and one build
  type, as described in
  [Composing profiles](https://github.com/bitsorg/stacks.bits#composing-profiles). SHiP
  uses `gcc15::opt`, so builds run in `x86_64-el9-gcc15-opt`.
- **Pass the release on the command line** (`--set release=LCG_110`, or record it with
  `bits use` as above). The value selects the `lcg.bits` and `stacks.bits` branches, and
  it enters every package hash. A release chosen any other way hashes differently, so
  nothing built by the other groups is reused. The release must exist as a branch of
  both `lcg.bits` and `stacks.bits`.
- **Externals that replace the `lcg.bits` recipes.** Recipes in this repository come
  first on the search path, so these replace the `lcg.bits` recipe of the same name for
  the whole SHiP build:

  | Package | SHiP | `lcg.bits` | Why |
  |---|---|---|---|
  | `ROOT` | v6.38.00, built with Pythia8 | v6.40.02, Pythia8 off | FairShip uses TPythia8 |
  | `pythia6` | v6.4.28-snd | 429.2 | SHiP/SND-LHC sources with the ROOT TPythia6 interface |
  | `GENIE` | R-3_06_02 | 2.12.6 | FairShip needs GENIE 3 |

  Each replacement changes the hash of that package and of everything that depends on
  it, so those are rebuilt for SHiP. Everything below them is still reused.
- **Developing FairShip.** `bits init -c . FairShip` creates a writable FairShip
  checkout next to the recipes; later builds of `FairShip` use it. See the bits cookbook
  on [developing a single package](https://github.com/bitsorg/bits/blob/main/docs/COOKBOOK.md#develop-and-iterate-on-a-single-package).
- **Store and certification.** `defaults-ship.sh` also sets the binary store
  (`remote_store`), the certification group (`ship`) and the manifests repository used
  by `bits certify`.
- **Publishing to the testbed.** Append the `testbed` overlay from
  [testbed.bits](https://github.com/bitsorg/testbed.bits) as the last profile, for example
  `--defaults ship::gcc15::opt::testbed`. It changes only the CVMFS repository and keeps
  the layout.

### Where SHiP is published on CVMFS

SHiP software is published under `/cvmfs/bits.cern.ch/ship`, with the packages and
modulefiles templates of the shared
[stacks.bits layout](https://github.com/bitsorg/stacks.bits#cvmfs-layout). There is no
release view: the release and view templates are empty, so the path does not depend on
the release. `prefix` must match `cvmfs_prefix` in the bits-console SHiP community
configuration, or a build refuses to publish. To preview a path without building, run
`bits cvmfs-path -c . --defaults ship::gcc15::opt --admin --package <pkg> --version <v> --platform <arch>`.

## Files

| File | Purpose |
|---|---|
| `defaults-ship.sh` | SHiP overlay: `stacks.bits` base, release tracking, CVMFS layout, store policy, macOS ROOT pin |
| `fairship.sh`, `fairroot.sh`, `fairlogger.sh`, `faircmakemodules.sh`, `geant3.sh`, `rootegpythia6.sh` | The SHiP stack |
| `root.sh`, `pythia6.sh`, `genie.sh` | SHiP builds of externals that replace the `lcg.bits` recipes |
| `ninja-fortran.sh` | Kitware's Fortran-enabled ninja, a build tool for `pythia6` |
| `termcap.sh` | System check for `termcap.h` (ncurses development headers) |

## More information

- [FairShip](https://github.com/ShipSoft/FairShip) and
  [shipdist](https://github.com/ShipSoft/shipdist);
  [sharing binaries through a store](https://github.com/bitsorg/bits/blob/main/docs/USERGUIDE.md#sharing-binaries-through-a-store)
- [stacks.bits](https://github.com/bitsorg/stacks.bits#readme) and
  [lcg.bits](https://github.com/bitsorg/lcg.bits#readme) READMEs: profiles, releases,
  CVMFS layout and the recipe pool; [bits-providers](https://github.com/bitsorg/bits-providers): the registry
- bits [User Guide](https://github.com/bitsorg/bits/blob/main/docs/USERGUIDE.md),
  [Cookbook](https://github.com/bitsorg/bits/blob/main/docs/COOKBOOK.md),
  [Reference](https://github.com/bitsorg/bits/blob/main/docs/REFERENCE.md)
- [bits-console](https://gitlab.cern.ch/buncic/bits-console): CI builds and CVMFS publishing

## License

This repository does not contain a LICENSE file yet.
