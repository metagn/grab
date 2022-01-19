# Package

version       = "0.1.0"
author        = "metagn"
description   = "grab statement for importing Nimble packages, similar to Groovy's Grape"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 1.4.0"

when (NimMajor, NimMinor) >= (1, 4):
  when (compiles do: import nimbleutils):
    import nimbleutils
    # https://github.com/metagn/nimbleutils

task docs, "build docs for all modules":
  when declared(buildDocs):
    buildDocs(gitUrl = "https://github.com/metagn/grab")
  else:
    echo "docs task not implemented, need nimbleutils"

task tests, "run tests for multiple backends":
  when declared(runTests):
    runTests(backends = {c, nims})
  else:
    echo "tests task not implemented, need nimbleutils"
