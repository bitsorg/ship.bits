package: FairLogger
version: "%(tag_basename)s"
tag: v2.3.2
source: https://github.com/FairRootGroup/FairLogger
requires:
  - CMake
  - fmt
build_requires:
  - bits-recipe-tools
  - "GCC-Toolchain:(?!osx)"
prefer_system_check: |
  #!/bin/bash -e
  REQUESTED_VERSION=${REQUESTED_VERSION#v}
  verge() { [[  "$1" = "$(echo -e "$1\n$2" | sort -V | head -n1)" ]]; }
  verge $REQUESTED_VERSION $FAIRLOGGER_VERSION
---
#!/bin/bash -e
##############################
. $(bits-include CMakeRecipe)
##############################
MODULE_OPTIONS="--bin --lib --root-inc"
##############################
function Configure() {
  cmake -S "$BITS_CMAKE_SRC" -B "$BITS_CMAKE_BUILD" \
    -DCMAKE_INSTALL_PREFIX="$INSTALLROOT" \
    -DCMAKE_INSTALL_LIBDIR=lib \
    ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE} \
    ${CMAKE_PREFIX_PATH:+-DCMAKE_PREFIX_PATH="${CMAKE_PREFIX_PATH}"} \
    ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD} \
    -DDISABLE_COLOR=ON \
    -DUSE_EXTERNAL_FMT=ON
}

function UnitTest() {
  ctest --test-dir "$BITS_CMAKE_BUILD" ${JOBS:+-j$JOBS}
}
