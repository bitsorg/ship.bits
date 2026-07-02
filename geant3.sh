package: GEANT3
version: "%(tag_basename)s"
tag: v4-5
source: https://github.com/vmc-project/geant3
requires:
  - CMake
  - ROOT
  - vmc
build_requires:
  - bits-recipe-tools
  - "GCC-Toolchain:(?!osx)"
env:
  GEANT3DIR: "$GEANT3_ROOT"
  G3SYS: "$GEANT3_ROOT"
prepend_path:
  LD_LIBRARY_PATH: "$GEANT3_ROOT/lib64"
  ROOT_INCLUDE_PATH: "$GEANT3_ROOT/include/TGeant3"
prefer_system_check: |
  #!/bin/bash -e
  ls $GEANT3_ROOT/ > /dev/null && \
  ls $GEANT3_ROOT/include > /dev/null && \
  ls $GEANT3_ROOT/include/TGeant3 > /dev/null && \
  ls $GEANT3_ROOT/include/TGeant3/TGeant3.h > /dev/null && \
  ls $GEANT3_ROOT/lib64/libgeant321.so > /dev/null && \
  true
---
#!/bin/bash -e
##############################
. $(bits-include CMakeRecipe)
##############################
MODULE_OPTIONS="--root"
##############################
function Configure() {
  local FVERSION SPECIALFFLAGS=""
  FVERSION=$(gfortran --version | grep -i fortran | sed -e 's/.* //' | cut -d. -f1)
  if [ "${FVERSION:-0}" -ge 10 ]; then SPECIALFFLAGS=1; fi

  cmake -S "$BITS_CMAKE_SRC" -B "$BITS_CMAKE_BUILD"                    \
    -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                             \
    ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE}         \
    ${CMAKE_PREFIX_PATH:+-DCMAKE_PREFIX_PATH="${CMAKE_PREFIX_PATH}"}  \
    ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                           \
    -DCMAKE_SKIP_RPATH=TRUE                                           \
    -DCMAKE_POLICY_DEFAULT_CMP0074=NEW                                \
    -DCMAKE_POLICY_DEFAULT_CMP0144=NEW                                \
    -DCMAKE_C_FLAGS="$CFLAGS -std=gnu17"                              \
    ${SPECIALFFLAGS:+-DCMAKE_Fortran_FLAGS="-fallow-argument-mismatch -fallow-invalid-boz -fno-tree-loop-distribute-patterns"}
}

function PostInstall() {
  # GEANT3 expects its libraries under lib64; if the install used lib, add a
  # lib64 -> lib symlink so consumers and the prefer_system_check resolve.
  if [[ ! -d "$INSTALLROOT/lib64" ]]; then
    ln -sf lib "$INSTALLROOT/lib64"
  fi
}
