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
  `x86_64-ubuntu2604`; published on CVMFS today is `x86_64-el9` (gcc15 and gcc14, `opt`).
  Pass it as `--architecture`; on one of them, `bits architecture` prints it. See [Finding a platform
  with pre-built
  binaries](https://github.com/bitsorg/bits/blob/main/docs/USERGUIDE.md#finding-a-platform-with-pre-built-binaries).
- On macOS (a native build), `defaults-ship.sh` switches ROOT to v6.40.00 for Apple clang
  and Xcode.
- Network access while FairShip builds: its git-lfs files come from
  `media.githubusercontent.com` (with `--sandbox`, the recipe allows it).
- Read access to the SHiP binary store set in `defaults-ship.sh`
  (`https://s3.cern.ch/swift/v1/lcgapp-bits-testing`). bits fetches prebuilt packages from
  it by default.

## Using the published FairShip

FairShip is published on CVMFS under `/cvmfs/bits.cern.ch/ship`, now `26.06` for
`x86_64-el9-gcc15-opt` and `x86_64-el9-gcc14-opt`, with everything it needs, so nothing
has to be built or checked out:

```bash
export BITS_CVMFS_PREFIX=/cvmfs/bits.cern.ch/ship
bits q -a x86_64-el9-gcc15-opt FairShip            # the published versions
bits enter -a x86_64-el9-gcc15-opt FairShip/<version>
```

`BITS_CVMFS_PREFIX` names SHiP's tree (with the CVMFS entry point
`/cvmfs/bits.cern.ch/bits/bin/bits`, `bits --community ship ...` sets it). `bits enter`
opens a sub-shell with FairShip and its dependencies loaded from the CVMFS modules (SHiP
has no release view); leave it with `exit`. In it, run FairShip as its README describes
([Running a simulation](#running-a-simulation)). The revisions published before the
recipes set FairShip's run-time environment in its module and fetched its git-lfs files
(`26.06-1` and `26.06-2`) lack `$FAIRSHIP` and the field maps; use a later one.

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

### Running a simulation

In `bits enter FairShip/...`, as in [FairShip's README](https://github.com/ShipSoft/FairShip#run-instructions):

```bash
python $FAIRSHIP/macro/run_simScript.py --tag my-simulation        # sim_ and geo_my-simulation.root
python $FAIRSHIP/macro/ShipReco.py -f sim_my-simulation.root -g geo_my-simulation.root
python -i $FAIRSHIP/macro/ShipAna.py -f sim_my-simulation.root -r sim_my-simulation_rec.root -g geo_my-simulation.root
```

The modules set what FairShip's scripts read: `FAIRSHIP` and `VMCWORKDIR` (the FairShip
tree), `GEOMPATH`, `CONFIG_DIR`, `GALCONF`, `FAIRLIBDIR`, `EOSSHIP` and FairShip's
`python/` on `PYTHONPATH`; GENIE's `GENIE`, GEANT3's `G3SYS` and Pythia8's `PYTHIA8DATA`.
FairShip keeps its `.root` inputs (field maps, ...) in git-lfs; the recipe downloads them
from GitHub while it builds, so no `git lfs` is needed.

## Notes for SHiP users

- **bits, pixi and the legacy releases.** FairShip's own README builds it with pixi from
  conda-forge, and keeps `/cvmfs/ship.cern.ch` releases (aliBuild and shipdist, up to
  26.04) for older work. ship.bits builds the same FairShip with bits, from the shipdist
  recipes ported to bits, with SHiP's ROOT, pythia6 and GENIE and the rest from
  `lcg.bits`, and publishes it under `/cvmfs/bits.cern.ch/ship`.

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
