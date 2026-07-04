package: pythia6
description: Pythia 6 with the ROOT/TPythia6 interface glue (SHiP/SND-LHC sources)
version: "%(tag_basename)s"
tag: "v6.4.28-snd"
source: https://github.com/SND-LHC/pythia6

build_requires:
  - CMake
  - ninja-fortran
  - bits-recipe-tools
  - "GCC-Toolchain:(?!osx)"
license: LicenseRef-Pythia6
prepend_path:
  AGILE_GEN_PATH: "$PYTHIA6_ROOT"
---
#!/bin/bash -e
##############################
. $(bits-include CMakeRecipe)
##############################
MODULE_OPTIONS="--lib"
##############################
# alisw/pythia6 is a CMake (Ninja-fortran) project that compiles the Pythia6
# Fortran together with the ROOT interface glue (pythia6_common_address,
# tpythia6_{open,close}_fortran_file), so libpythia6 carries the symbols
# TPythia6/ROOTEGPythia6 need. Builds on macOS, as ALICE does.
function Configure() {
  cmake -S "$BITS_CMAKE_SRC" -B "$BITS_CMAKE_BUILD"                    \
    -G Ninja                                                          \
    -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                             \
    -DCMAKE_INSTALL_LIBDIR=lib                                        \
    ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE}         \
    ${CMAKE_PREFIX_PATH:+-DCMAKE_PREFIX_PATH="${CMAKE_PREFIX_PATH}"}  \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5
}
