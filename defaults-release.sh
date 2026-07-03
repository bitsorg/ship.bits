package: defaults-release
version: v1
# Optional: override the architecture-string layout. A literal value or a
# template using %(os)s (e.g. ubuntu2510), %(machine)s (x86-64, dashed) and
# %(_machine)s (x86_64, underscore). The built-in default is %(os)s_%(machine)s.
# An explicit --architecture on the command line always overrides this.
#   architecture: %(os)s_%(machine)s     # ubuntu2510_x86-64  (default layout)
#   architecture: %(os)s_%(_machine)s    # ubuntu2510_x86_64
#   architecture: %(_machine)s-%(os)s    # x86_64-ubuntu2510

# Optional: declare the CVMFS layout once so the build/publish/reuse paths are
# derived instead of passed as scattered flags. Templates may use
# %(architecture)s (the effective, combined arch). install_dir / module_dir are
# relative to cvmfs_dir.
#   * docker build    -> --cvmfs-prefix defaults to <cvmfs_dir>/<install_dir>
#   * --reuse-cvmfs   -> --remote-store defaults to cvmfs://<cvmfs_dir>
# cvmfs_dir:   /cvmfs/sft.cern.ch/lcg/releases
# install_dir: %(architecture)s/Packages
# module_dir:  %(architecture)s/modules

# Build-host policy: how the build *runs* (network, CPU), not what it produces.
# Keys under `system:` are NOT part of any package hash, so changing them never
# triggers a rebuild — unlike `env:` below, which is hashed.
system:
  sandbox_network: "off"
  build_oversubscribe: 1.25
  # Read store here (under system:, so NOT hashed — unlike env:). CLI/bits.rc and
  # BITS_REMOTE_STORE/REMOTE_STORE env still override it.
  remote_store: "https://s3.cern.ch/swift/v1/lcgapp-bits-testing"

env:
  CXXFLAGS: "-fPIC -g -O2"
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
