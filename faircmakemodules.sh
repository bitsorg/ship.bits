package: FairCMakeModules
version: "%(tag_basename)s"
tag: v1.0.0
source: https://github.com/FairRootGroup/FairCMakeModules
requires:
  - CMake
build_requires:
  - bits-recipe-tools
  - "GCC-Toolchain:(?!osx)"
prefer_system_check: |
    if [ ! -z "$FAIRCMAKEMODULES_VERSION" ]; then
        exit 0
    fi
    exit 1
---
#!/bin/bash -e
##############################
. $(bits-include CMakeRecipe)
##############################
# CMake-modules only package; consumers find it via CMAKE_PREFIX_PATH.
MODULE_OPTIONS="--root --cmake"
