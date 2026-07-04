package: ninja-fortran
version: "fortran-%(short_hash)s"
tag: "v1.11.1.g95dee.kitware.jobserver-1"
source: https://github.com/Kitware/ninja
build_requires:
  - "GCC-Toolchain:(?!osx)"
  - CMake
  - bits-recipe-tools
---
#!/bin/bash -e
##############################
. $(bits-include CMakeRecipe)
##############################
MODULE_OPTIONS="--bin"
##############################
# Kitware's Ninja fork with Fortran-module dependency support. The default
# Configure/Make (Unix Makefiles) build the `ninja` binary in the build dir;
# install just that.
function MakeInstall() {
  install -dm755 "$INSTALLROOT/bin"
  install -m755 "$BITS_CMAKE_BUILD/ninja" "$INSTALLROOT/bin/"
}
