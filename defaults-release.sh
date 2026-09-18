package: defaults-release
version: v1
# Optional: override the architecture-string layout. A literal value or a
# template using %(os)s (e.g. ubuntu2510), %(machine)s (x86-64, dashed) and
# %(_machine)s (x86_64, underscore). The built-in default is %(os)s_%(machine)s.
# An explicit --architecture on the command line always overrides this.
architecture: "%(os)s_%(machine)s"       # ubuntu2510_x86-64  (default layout)
system:
  sandbox_network: "off"
  build_oversubscribe: 1.25
  remote_store:  "https://s3.cern.ch/swift/v1/lcgapp-bits-testing"
  certify_group: "ship"
  manifests_remote: "https://gitlab.cern.ch/buncic/bits-manifests.git"
  # CVMFS path templates 
  # {prefix} is the releases ROOT (auth boundary). bits-console (ui-config.yaml:
  # cvmfs_prefix) injects the authoritative value, which WINS; the value below MUST
  # match it (kept in sync by bits-admin PR) or an injected build refuses to publish.
  # It lets local `bits build` (no injection) work and is a checked declaration.
  prefix:                     "/cvmfs/sft-nightlies-test.cern.ch/ship/releases"
  cvmfs_user_prefix:          "/cvmfs/sft-nightlies-test.cern.ch/ship/user"
  cvmfs_releases_template:        "{prefix}/{pkg}/{tag}/{platform}"
  cvmfs_modules_template:     "{prefix}/{platform}/Modules/modulefiles/{pkg}"
  cvmfs_shared_path_template: "{prefix}/noarch/{pkg}/{tag}"
  
env:
  # No CXXFLAGS/-std here: the C++ standard is owned by the compiler-axis defaults
  # (stacks.bits/defaults-gccNN, defaults-clang) per compiler capability, not this
  # base profile.
  CFLAGS: "-fPIC -g -O2"
  CMAKE_BUILD_TYPE: "RELWITHDEBINFO"
  MACOSX_DEPLOYMENT_TARGET: '14.0'
  ENABLE_IPO: 'OFF'

variables:
  lcgversion: main

requires:
  - lcg.bits

overrides:
  lcg.bits:
    tag: "%(lcgversion)s"
---
