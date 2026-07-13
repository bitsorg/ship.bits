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
  prefix:                     "/cvmfs/sft-nightlies-test.cern.ch/ship/releases"
  cvmfs_user_prefix:          "/cvmfs/sft-nightlies-test.cern.ch/ship/user" 
  cvmfs_path_template:        "{prefix}/{pkg}/{tag}/{platform}"
  cvmfs_modules_template:     "{prefix}/{platform}/Modules/modulefiles/{pkg}"
  cvmfs_shared_path_template: "{prefix}/noarch/{pkg}/{tag}"
  
env:
  CFLAGS: "-fPIC -g -O2"
  CXXSTD: '23'
  CXXFLAGS: "${CFLAGS} -std=c++${CXXSTD}"
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
