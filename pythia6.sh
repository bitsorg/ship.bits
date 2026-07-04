package: pythia6
description: Pythia 6 with the ROOT/TPythia6 interface glue (SHiP/SND-LHC sources)
version: "6.4.28.snd"
tag: "v6.4.28-snd"
source: https://github.com/SND-LHC/pythia6
build_requires:
  - bits-recipe-tools
  - "GCC-Toolchain:(?!osx)"
license: LicenseRef-Pythia6
---
#!/bin/bash -e
##############################
. $(bits-include MakeRecipe)
##############################
MODULE_OPTIONS="--lib"
##############################
# Unlike the bare-Fortran lcg.bits pythia6, this builds the SND-LHC sources,
# which include the ROOT interface glue that TPythia6/ROOTEGPythia6 needs:
#   pythia6_common_address.c    -> pythia6_common_address (Fortran common-block addresses)
#   tpythia6_called_from_cc.F   -> tpythia6_{open,close}_fortran_file (single underscore)
# Both must be linked into libpythia6, else EGPythia6 fails with undefined symbols.
function Make() {
  local fflags="-std=legacy -fallow-argument-mismatch -O2 -fPIC"
  # macOS shared libs are .dylib built with -dynamiclib. PYTHIA6 references PDF
  # routines (structm_, pdfset_, ...) not in these objects; macOS's two-level
  # namespace rejects undefined symbols in a dylib whereas Linux's flat namespace
  # allows them, so allow flat-namespace lazy resolution. -headerpad reserves
  # Mach-O header space for bits' relocate-me.sh to rewrite the install name.
  local _so=so _shared=-shared _undef=
  if [ "$(uname)" = Darwin ]; then
    _so=dylib; _shared=-dynamiclib
    _undef="-Wl,-undefined,dynamic_lookup -Wl,-headerpad_max_install_names"
  fi

  # Prefer the 6.4.28 Fortran; fall back to whatever pythia6*.f the tag ships.
  local main_f=""
  for c in pythia6428.f pythia6416.f $(ls pythia6*.f 2>/dev/null); do
    [ -f "$c" ] && main_f="$c" && break
  done
  [ -n "$main_f" ] || { echo "ERROR: no pythia6*.f in the source tree"; exit 1; }

  ${FC:-gfortran} $fflags -c "$main_f" -o pythia6.o
  # -fno-second-underscore keeps the glue's file-I/O names single-underscored to
  # match the C++ callers (tpythia6_open_fortran_file_).
  ${FC:-gfortran} $fflags -fno-second-underscore -c tpythia6_called_from_cc.F -o tpythia6_called_from_cc.o
  ${CC:-cc} -O2 -fPIC -c pythia6_common_address.c -o pythia6_common_address.o

  local objs="pythia6.o tpythia6_called_from_cc.o pythia6_common_address.o"
  # shellcheck disable=SC2086
  ${FC:-gfortran} $fflags $_shared $_undef -o "libpythia6.$_so" $objs
  # shellcheck disable=SC2086
  ${AR:-ar} crs libpythia6.a $objs
}

function MakeInstall() {
  local _so=so; [ "$(uname)" = Darwin ] && _so=dylib
  install -dm755 "$INSTALLROOT/lib"
  install -m755 "libpythia6.$_so" "$INSTALLROOT/lib/"
  install -m644 libpythia6.a      "$INSTALLROOT/lib/"
}
