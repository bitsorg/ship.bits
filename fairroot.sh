package: FairRoot
version: "%(tag_basename)s"
tag: "v19.0.1"
source: https://github.com/FairRootGroup/FairRoot
requires:
  - CMake
  - pythia8
  - pythia6
  - evtgen
  - geant4_vmc
  - Geant4
  - HepMC
  - ROOT
  - vmc
  - Boost
  - FairLogger
  - yamlcpp
  - GEANT3
build_requires:
  - bits-recipe-tools
  - "GCC-Toolchain:(?!osx)"
  - FairCMakeModules
env:
  VMCWORKDIR: "$FAIRROOT_ROOT/share/fairbase/examples"
  GEOMPATH: "$FAIRROOT_ROOT/share/fairbase/examples/common/geometry"
  CONFIG_DIR: "$FAIRROOT_ROOT/share/fairbase/examples/common/gconfig"
  FAIRROOTPATH: "$FAIRROOT_ROOT"
prefer_system_check: |
  ls $FAIRROOT_ROOT/ > /dev/null && \
  ls $FAIRROOT_ROOT/lib > /dev/null && \
  ls $FAIRROOT_ROOT/include > /dev/null
---
#!/bin/bash -e
##############################
. $(bits-include CMakeRecipe)
##############################
MODULE_OPTIONS="--bin --lib --root-inc"
##############################
function Configure() {
  # SIMPATH is hardcoded in several FairRoot places; unset it so it cannot leak
  # in from the build environment.
  unset SIMPATH

  # Patch the private source copy (BITS_CMAKE_SRC); SOURCES is mounted read-only.
  # Use perl for in-place edits: BSD/macOS `sed -i` and GNU-only
  # `xargs --no-run-if-empty` are not portable and silently no-op here.
  #
  # Upstream FairRoot bug (<= v19.0.1): the propagator example links
  # Boost::serialization but the component is only requested under BUILD_BASEMQ,
  # so with BUILD_BASEMQ=OFF the imported target is missing. Request it
  # unconditionally just before find_package2(Boost). (upstream PR #1631)
  # shellcheck disable=SC2016
  perl -i -pe 's{^(\s*find_package2\(PUBLIC Boost)}{  list(APPEND boost_dependencies serialization)\n$1}' \
    "$BITS_CMAKE_SRC/CMakeLists.txt"

  # Upstream FairRoot (<= v19.0.1) includes <fmt/core.h> but calls fmt::format,
  # which since fmt 11.1/12.0 lives in <fmt/format.h>. Rewrite the includes.
  # shellcheck disable=SC2016
  grep -rl '#include <fmt/core.h>' "$BITS_CMAKE_SRC" | while IFS= read -r f; do
    perl -i -pe 's{#include <fmt/core.h>}{#include <fmt/format.h>}' "$f"
  done

  [[ -n $BOOST_ROOT ]] && BOOST_NO_SYSTEM_PATHS=ON || BOOST_NO_SYSTEM_PATHS=OFF
  cmake -S "$BITS_CMAKE_SRC" -B "$BITS_CMAKE_BUILD"                    \
    ${CMAKE_GENERATOR:+-G "$CMAKE_GENERATOR"}                         \
    -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                             \
    -DCMAKE_INSTALL_LIBDIR=lib                                        \
    ${CMAKE_PREFIX_PATH:+-DCMAKE_PREFIX_PATH="${CMAKE_PREFIX_PATH}"}  \
    -DCMAKE_CXX_FLAGS="$CXXFLAGS"                                     \
    -DCMAKE_CATCH_DISCOVER_TESTS_DISCOVERY_MODE=PRE_TEST             \
    ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE}         \
    -DROOTSYS=$ROOTSYS                                                \
    -DPythia6_LIBRARY_DIR=$PYTHIA6_ROOT/lib                           \
    ${YAMLCPP_ROOT:+-DYAML_CPP_ROOT=$YAMLCPP_ROOT}                    \
    ${GEANT3_ROOT:+-DGeant3_DIR=$GEANT3_ROOT}                         \
    -DBUILD_EXAMPLES=ON                                               \
    ${GEANT4_ROOT:+-DGeant4_DIR=$GEANT4_ROOT}                         \
    ${GEANT4_VMC_ROOT:+-DGeant4VMC_ROOT=$GEANT4_VMC_ROOT}             \
    ${XERCESC_ROOT:+-DXercesC_ROOT=$XERCESC_ROOT}                     \
    ${BOOST_ROOT:+-DBOOST_ROOT=$BOOST_ROOT}                           \
    -DBoost_NO_SYSTEM_PATHS=${BOOST_NO_SYSTEM_PATHS}                  \
    ${GSL_ROOT:+-DGSL_DIR=$GSL_ROOT}                                  \
    ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                           \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON                                \
    -DCMAKE_POLICY_DEFAULT_CMP0167=NEW                                \
    -DFairCMakeModules_ROOT=$FAIRCMAKEMODULES_ROOT                    \
    -DBUILD_BASEMQ=OFF
}

function PostInstall() {
  # Work around hardcoded relative include paths baked into the ROOT PCMs.
  local d
  for d in source sink field event sim steer; do
    ln -nfs ../include "$INSTALLROOT/include/$d"
  done
  # Record the git hash (informational; consumed downstream by FairShip).
  local h; h=$(git -C "$BITS_CMAKE_SRC" rev-parse HEAD 2>/dev/null || echo unknown)
  echo "setenv FAIRROOT_HASH $h" >> "$MODULEFILE"
}
