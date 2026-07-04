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
  # Patch the private source copy (BITS_CMAKE_SRC); SOURCES is read-only. Use
  # perl for in-place edits: it behaves identically everywhere, unlike GNU vs
  # BSD (macOS) `sed -i` and sed's one-line insert.

  # 1) Pass bare header names to ROOT_GENERATE_DICTIONARY (absolute paths get
  #    baked into $clingAutoload$ and break once the build dir is gone), and add
  #    the include dir so the headers still resolve.
  # shellcheck disable=SC2016
  perl -i -pe 's{\$\{CMAKE_CURRENT_LIST_DIR\}/inc/(.*\.h)}{$1}g; s{^ROOT_GENERATE_DICTIONARY}{include_directories(\${CMAKE_CURRENT_LIST_DIR}/inc)\nROOT_GENERATE_DICTIONARY}g;' \
    "$BITS_CMAKE_SRC/CMakeLists.txt"

  # 2) The bundled FindPythia6 hardcodes libPythia6.so; bits installs
  #    lib/libpythia6.<ext> (.dylib on macOS, .so on Linux). Point it at the
  #    correct name and platform suffix.
  # shellcheck disable=SC2016
  perl -i -pe 's{libPythia6\.so}{libpythia6\${CMAKE_SHARED_LIBRARY_SUFFIX}}g;' \
    "$BITS_CMAKE_SRC/cmake/Modules/FindPythia6.cmake"

  # 3) Define the namespaced Pythia6::Pythia6 imported target directly in the
  #    installed package config so downstream consumers don't depend on whichever
  #    FindPythia6 they load first.
  # shellcheck disable=SC2016
  perl -0pi -e 's{find_package\(Pythia6 REQUIRED\)}{if(NOT TARGET Pythia6::Pythia6)\n  add_library(Pythia6::Pythia6 SHARED IMPORTED)\n  set_target_properties(Pythia6::Pythia6 PROPERTIES IMPORTED_LOCATION "\$ENV{PYTHIA6_ROOT}/lib/libpythia6\${CMAKE_SHARED_LIBRARY_SUFFIX}")\nendif()}g;' \
    "$BITS_CMAKE_SRC/cmake/Templates/ROOTEGPythia6Config.cmake.in"

  # 4) The config's own ROOTEGPythia6_LIB_DIR probe hardcodes libEGPythia6.so;
  #    match the platform suffix so find_package(ROOTEGPythia6) resolves on macOS.
  # shellcheck disable=SC2016
  perl -i -pe 's{libEGPythia6\.so}{libEGPythia6\${CMAKE_SHARED_LIBRARY_SUFFIX}}g' \
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
  # ROOT scans *.rootmap by content, so the filename is cosmetic. Match either
  # extension so it works on macOS (.dylib) and Linux (.so).
  perl -i -pe 's{\blibTPythia6\.(so|dylib)\b}{libEGPythia6.$1}g' "$INSTALLROOT/lib/libTPythia6.rootmap"
  mv "$INSTALLROOT/lib/libTPythia6.rootmap" "$INSTALLROOT/lib/libEGPythia6.rootmap"
  # Do NOT rename libTPythia6_rdict.pcm: the literal name is baked into the
  # dictionary registration; TCling looks it up by dictionary name (TPythia6).
}
