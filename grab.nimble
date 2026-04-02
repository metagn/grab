# Package

version       = "0.1.2"
author        = "metagn"
description   = "grab statement for importing Nimble packages, similar to Groovy's Grape"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 1.0.0"

task docs, "build docs for all modules":
  exec "nim r tasks/build_docs.nim"

task tests, "run tests for multiple backends":
  exec "nim r tasks/run_tests.nim"
