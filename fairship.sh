package: FairShip
version: "%(tag_basename)s"
tag: "26.06"
source: https://github.com/ShipSoft/FairShip
requires:
  - CMake
  - pythia8
  - pythia6
  - geant4_vmc
  - HepMC
  - FairRoot
  - FairLogger
  - GENIE
  - genfit
  - Geant4
  - photoscpp
  - evtgen
  - ROOT
  - ROOTEGPythia6
  - vmc
  - matplotlib
  - pandas
  - PyYAML
  - pytest_xdist
  - scipy
  - tabulate
  - hepmc3
  - acts
build_requires:
  - bits-recipe-tools
  - "GCC-Toolchain:(?!osx)"
  - FairCMakeModules
  - ninja
env:
  FAIRSHIP: "$FAIRSHIP_ROOT"
  EOSSHIP: "root://eospublic.cern.ch/"
  VMCWORKDIR: "$FAIRSHIP_ROOT"
  GEOMPATH: "$FAIRSHIP_ROOT/geometry"
  CONFIG_DIR: "$FAIRSHIP_ROOT/gconfig"
  GALCONF: "$FAIRSHIP_ROOT/shipgen/genie_config"
  FAIRLIBDIR: "$FAIRSHIP_ROOT/lib"
prepend_path:
  PYTHONPATH: "$FAIRSHIP_ROOT/python"
append_path:
  ROOT_INCLUDE_PATH:
    - "$GEANT4_ROOT/include"
    - "$GEANT4_ROOT/include/Geant4"
    - "$PYTHIA8_ROOT/include"
    - "$PYTHIA8_ROOT/include/Pythia8"
    - "$GEANT4_VMC_ROOT/include"
    - "$GEANT4_VMC_ROOT/include/geant4vmc"
---
#!/bin/bash -e
##############################
. $(bits-include CMakeRecipe)
##############################
MODULE_OPTIONS="--bin --lib --root-inc"
##############################
function Configure() {
  # FairShip runs from its installed source tree (python/, geometry/, gconfig/).
  # Copy the private source copy into INSTALLROOT; the CMake install below then
  # overlays the compiled libraries on top.
  rsync -a "$BITS_CMAKE_SRC"/ "$INSTALLROOT"/

  # FairShip is Linux-first: many targets under-link ROOT (Physics/EG/VMC) and
  # FairRoot base libs, relying on Linux's flat namespace to resolve them lazily.
  # macOS's two-level namespace needs them at link time; allow load-time lookup
  # (as FairRoot/ROOT themselves do) so the dylibs link.
  local -a _macos_ld=()
  if [ "$(uname)" = Darwin ]; then
    _macos_ld=(
      "-DCMAKE_SHARED_LINKER_FLAGS=-undefined dynamic_lookup"
      "-DCMAKE_MODULE_LINKER_FLAGS=-undefined dynamic_lookup"
      "-DCMAKE_EXE_LINKER_FLAGS=-undefined dynamic_lookup"
    )
  fi

  cmake -S "$BITS_CMAKE_SRC" -B "$BITS_CMAKE_BUILD"                    \
    "${_macos_ld[@]}"                                                 \
    -G Ninja                                                          \
    -DFAIRBASE="$FAIRROOT_ROOT/share/fairbase"                        \
    -DFAIRROOTPATH="$FAIRROOT_ROOT"                                   \
    -DFAIRROOT_INCLUDE_DIR="$FAIRROOT_ROOT/include"                   \
    -DFAIRROOT_LIBRARY_DIR="$FAIRROOT_ROOT/lib"                       \
    -DFMT_INCLUDE_DIR="$FMT_ROOT/include"                             \
    -DCMAKE_CXX_FLAGS="$CXXFLAGS"                                     \
    ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE}         \
    ${CMAKE_PREFIX_PATH:+-DCMAKE_PREFIX_PATH="${CMAKE_PREFIX_PATH}"}  \
    -DROOT_DIR="$ROOT_ROOT"                                           \
    ${ROOTEGPYTHIA6_ROOT:+-DROOTEGPythia6_ROOT=$ROOTEGPYTHIA6_ROOT}   \
    -DEVTGEN_INCLUDE_DIR="$EVTGEN_ROOT/include"                       \
    -DEVTGEN_LIBRARY_DIR="$EVTGEN_ROOT/lib"                           \
    -DPYTHIA8_DIR="$PYTHIA8_ROOT"                                     \
    -DPYTHIA8_INCLUDE_DIR="$PYTHIA8_ROOT/include"                     \
    -DGEANT4_ROOT="$GEANT4_ROOT"                                      \
    -DGEANT4_INCLUDE_DIR="$GEANT4_ROOT/include/Geant4"                \
    -DGEANT4_VMC_INCLUDE_DIR="$GEANT4_VMC_ROOT/include/geant4vmc"     \
    ${CMAKE_VERBOSE_MAKEFILE:+-DCMAKE_VERBOSE_MAKEFILE=ON}            \
    -DFairCMakeModules_ROOT="$FAIRCMAKEMODULES_ROOT"                  \
    ${GENFIT_ROOT:+-Dgenfit2_ROOT=$GENFIT_ROOT}                       \
    ${ACTS_ROOT:+-DACTS_ROOT=$ACTS_ROOT}                              \
    -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"
}

function PostInstall() {
  # Record the git hash (informational metadata in the modulefile).
  local h; h=$(git -C "$BITS_CMAKE_SRC" rev-parse HEAD 2>/dev/null || echo unknown)
  echo "setenv FAIRSHIP_HASH $h" >> "$MODULEFILE"
}
