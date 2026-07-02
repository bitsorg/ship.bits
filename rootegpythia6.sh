package: ROOTEGPythia6
version: "%(tag_basename)s"
tag: feb7c7eb8d368aee20bf1cb01f1bbfb9cfaeb6b5
source: https://github.com/luketpickering/ROOTEGPythia6
requires:
  - CMake
  - ROOT
  - pythia6
build_requires:
  - bits-recipe-tools
  - "GCC-Toolchain:(?!osx)"
env:
  ROOTEGPYTHIA6: "$ROOTEGPYTHIA6_ROOT"
prepend_path:
  CMAKE_MODULE_PATH: "$ROOTEGPYTHIA6_ROOT/lib/cmake/ROOTEGPythia6/Modules"
prefer_system_check: |
    if [ ! -z "$ROOTEGPYTHIA6_VERSION" ]; then
        exit 0
    fi
    exit 1
---
#!/bin/bash -e
##############################
. $(bits-include CMakeRecipe)
##############################
MODULE_OPTIONS="--bin --lib --root-inc"
##############################
function Configure() {
  # Patch the private source copy (BITS_CMAKE_SRC); SOURCES is read-only.
  # 1) Pass bare header names to ROOT_GENERATE_DICTIONARY instead of absolute
  #    paths, which otherwise get baked into $clingAutoload$ and break at
  #    runtime once the build dir is gone (e.g. on CVMFS).
  # shellcheck disable=SC2016
  sed -i \
    -e 's|${CMAKE_CURRENT_LIST_DIR}/inc/\(.*\.h\)|\1|g' \
    -e '/^ROOT_GENERATE_DICTIONARY/i include_directories(${CMAKE_CURRENT_LIST_DIR}/inc)' \
    "$BITS_CMAKE_SRC/CMakeLists.txt"

  # 2) Define the namespaced Pythia6::Pythia6 imported target directly so we do
  #    not depend on whichever FindPythia6 a downstream consumer loads first.
  sed -i 's|find_package(Pythia6 REQUIRED)|if(NOT TARGET Pythia6::Pythia6)\n  if(NOT DEFINED ENV{PYTHIA6_ROOT} OR NOT EXISTS "$ENV{PYTHIA6_ROOT}/lib/libPythia6.so")\n    message(FATAL_ERROR "ROOTEGPythia6 requires PYTHIA6_ROOT to point to a directory containing lib/libPythia6.so")\n  endif()\n  add_library(Pythia6::Pythia6 SHARED IMPORTED)\n  set_target_properties(Pythia6::Pythia6 PROPERTIES IMPORTED_LOCATION "$ENV{PYTHIA6_ROOT}/lib/libPythia6.so")\nendif()|' \
    "$BITS_CMAKE_SRC/cmake/Templates/ROOTEGPythia6Config.cmake.in"

  cmake -S "$BITS_CMAKE_SRC" -B "$BITS_CMAKE_BUILD"                    \
    -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                             \
    -DCMAKE_INSTALL_LIBDIR=lib                                        \
    ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE}         \
    ${CMAKE_PREFIX_PATH:+-DCMAKE_PREFIX_PATH="${CMAKE_PREFIX_PATH}"}  \
    -DROOTEGPythia6_Pythia6_BUILTIN=OFF                               \
    -DPYTHIA6_LIB_DIR="$PYTHIA6_ROOT/lib"                             \
    -DCMAKE_POLICY_DEFAULT_CMP0144=NEW
}

function PostInstall() {
  # Fix rootmap: the dictionary is named TPythia6 but the library is EGPythia6.
  # ROOT scans *.rootmap by content, so the filename is cosmetic.
  sed -i 's/libTPythia6\.so/libEGPythia6.so/' "$INSTALLROOT/lib/libTPythia6.rootmap"
  mv "$INSTALLROOT/lib/libTPythia6.rootmap" "$INSTALLROOT/lib/libEGPythia6.rootmap"
  # Do NOT rename libTPythia6_rdict.pcm: the literal name is baked into the
  # dictionary registration; TCling looks it up by dictionary name (TPythia6).
}
