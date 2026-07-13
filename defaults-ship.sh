package: defaults-ship
version: v1
env:

overrides:
  # ROOT >= 6.40 on macOS for Apple-clang / Xcode compatibility; ":osx" gates it
  # to macOS arches, so Linux keeps the recipe default (v6-38-00).
  "ROOT:osx":
    version: "v6.40.00"
    tag: "v6-40-00"
---
