package: defaults-ship
version: v1
# SHIP group overlay — compose with:  --defaults ship[::gcc15::opt]
# Inherits shared env + package_family + release/lcg.bits tag wiring from
# stacks.bits (-> lcg.bits recipe pool); adds the ship CVMFS namespace, the S3
# store/certify policy, the arch-string layout, and a macOS ROOT pin.
requires:
  - stacks.bits

# Optional arch-string layout (default %(os)s_%(machine)s -> ubuntu2510_x86-64).
architecture: "%(os)s_%(machine)s"

# ship CVMFS namespace + store policy (system: is NOT hashed -> never affects reuse).
system:
  remote_store:     "https://s3.cern.ch/swift/v1/lcgapp-bits-testing"
  certify_group:    "ship"
  manifests_remote: "https://gitlab.cern.ch/buncic/bits-manifests.git"
  prefix:                     "/cvmfs/bits.cern.ch/ship/releases"
  cvmfs_user_prefix:          "/cvmfs/bits.cern.ch/ship/user"
  cvmfs_releases_template:    "{prefix}/{pkg}/{tag}/{platform}"
  cvmfs_modules_template:     "{prefix}/{platform}/Modules/modulefiles/{pkg}"
  cvmfs_shared_path_template: "{prefix}/noarch/{pkg}/{tag}"

overrides:
  # ROOT >= 6.40 on macOS for Apple-clang / Xcode compatibility; ":osx" gates it to
  # macOS arches, so Linux keeps the recipe default.
  "ROOT:osx":
    version: "v6.40.00"
    tag: "v6-40-00"
---
