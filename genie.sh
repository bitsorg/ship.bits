package: GENIE
description: Comprehensive Monte Carlo neutrino event generator (SHiP: GENIE 3)
version: "%(tag_basename)s"
tag: "R-3_06_02"
source: https://github.com/GENIE-MC/Generator
requires:
  - ROOT
  - lhapdf
  - apfel
  - pythia8
  - log4cpp
  - GSL
  - libxml2
build_requires:
  - bits-recipe-tools
  - "GCC-Toolchain:(?!osx)"
license: GENIE
env:
  GENIE: "$GENIE_ROOT/genie"
prepend_path:
  PATH: "$GENIE_ROOT/genie/bin"
  ROOT_INCLUDE_PATH: "$GENIE_ROOT/genie/inc:$GENIE_ROOT/genie/src"
  LD_LIBRARY_PATH: "$GENIE_ROOT/genie/lib"
---
#!/bin/bash -e
##############################
. $(bits-include AutoToolsRecipe)
##############################
MODULE_OPTIONS=""
##############################
# SHiP uses modern GENIE 3 (lhapdf6 + pythia8 + apfel), not the 2.12.6 line in
# lcg.bits. GENIE's makefiles reference $GENIE (the tree root); bits runs every
# phase in the same in-source build dir ($PWD).
export GENIE="$PWD"
export ROOTSYS="${ROOT_ROOT}"
export PATH="${ROOT_ROOT}/bin:$PATH"

function Configure() {
  # apfel is built with CMake (no libtool .la); point GENIE's configure at the
  # actual shared library (.dylib on macOS, .so on Linux). BSD/macOS-safe (perl).
  local soext=so; [ "$(uname)" = Darwin ] && soext=dylib
  # shellcheck disable=SC2016
  perl -i -pe "s{libAPFEL\\.la}{libAPFEL.$soext}g" configure

  ./configure --prefix="$INSTALLROOT"                                       \
    --enable-lhapdf6 --enable-apfel --enable-fnal --enable-validation-tools  \
    --enable-test --enable-boosted-dark-matter --enable-neutral-heavy-lepton \
    --enable-dark-neutrino --enable-rwght --disable-pythia6 --enable-pythia8  \
    --enable-mathmore                                                        \
    --with-pythia8-lib="${PYTHIA8_ROOT}/lib" --with-pythia8-inc="${PYTHIA8_ROOT}/include" \
    --with-lhapdf-lib="${LHAPDF_ROOT}/lib"   --with-lhapdf-inc="${LHAPDF_ROOT}/include"    \
    --with-libxml2-lib="${LIBXML2_ROOT}/lib" --with-libxml2-inc="${LIBXML2_ROOT}/include/libxml2" \
    --with-log4cpp-inc="${LOG4CPP_ROOT}/include" --with-log4cpp-lib="${LOG4CPP_ROOT}/lib" \
    --with-apfel-inc="${APFEL_ROOT}/include" --with-apfel-lib="${APFEL_ROOT}/lib"
}

function Make() {
  make ${JOBS:+-j $JOBS} CXXFLAGS="-Wall ${CXXFLAGS}" CFLAGS="-Wall ${CFLAGS}"
}

function MakeInstall() {
  # GENIE 3's `make install` is unreliable; stage the build tree by hand under
  # genie/ (its runtime expects $GENIE/{config,data,src,inc,lib,bin}).
  mkdir -p "$INSTALLROOT/genie"/{lib,bin,data,config,src,inc}
  rsync -a lib/    "$INSTALLROOT/genie/lib/"
  rsync -a bin/    "$INSTALLROOT/genie/bin/"
  rsync -a data/   "$INSTALLROOT/genie/data/"
  rsync -a config/ "$INSTALLROOT/genie/config/"
  rsync -a src/    "$INSTALLROOT/genie/src/"
  # ROOT dictionaries alongside the libs, public headers under inc/.
  find src -name '*.pcm' -exec rsync -a {} "$INSTALLROOT/genie/lib/" \;
  find src -name '*.h'   -exec rsync -a {} "$INSTALLROOT/genie/inc/" \;
}
