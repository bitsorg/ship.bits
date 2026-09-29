package: defaults-ship
version: v1
# SHIP group overlay — compose with:  --defaults ship[::gcc15::opt]
# Inherits shared env + package_family from stacks.bits (-> lcg.bits recipe
# pool); adds the ship CVMFS namespace, the S3 store/certify policy, and a macOS
# ROOT pin. The release comes from the command line (--set release=LCG_110);
# `main` is only the default.
variables:
  release: "main"

requires:
  - stacks.bits

# ship CVMFS namespace + store policy (system: is NOT hashed -> never affects reuse).
system:
  remote_store:     "https://s3.cern.ch/swift/v1/lcgapp-bits-testing"
  certify_group:    "ship"
  manifests_remote: "https://gitlab.cern.ch/buncic/bits-manifests.git"
  prefix:                     "/cvmfs/bits.cern.ch/ship/releases"
  cvmfs_user_prefix:          "/cvmfs/bits.cern.ch/ship/user"
  # <release>/<pkg>/<version>/<arch>: {arch} is the build arch
  # (x86_64-el9-gcc15-opt), so compilers/build types do not collide; {version}
  # has no bits revision, so within one release a rebuilt package of the same
  # version conflicts with the published one (replace: PREPUB_REPLACE_ON_CONFLICT).
  cvmfs_releases_template:    "{prefix}/{release}/{pkg}/{version}/{arch}"
  cvmfs_modules_template:     "{prefix}/{release}/{arch}/Modules/modulefiles/{pkg}"
  cvmfs_shared_path_template: "{prefix}/{release}/noarch/{pkg}/{version}"

overrides:
  lcg.bits:
    tag: "%(release)s"
  stacks.bits:
    tag: "%(release)s"

  # ROOT >= 6.40 on macOS for Apple-clang / Xcode compatibility; ":osx" gates it to
  # macOS arches, so Linux keeps the recipe default.
  "ROOT:osx":
    version: "v6.40.00"
    tag: "v6-40-00"
---
