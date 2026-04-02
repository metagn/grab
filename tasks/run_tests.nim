when (NimMajor, NimMinor) >= (1, 4):
  when (compiles do: import nimbleutils):
    import nimbleutils
    # https://github.com/metagn/nimbleutils

when not declared(runTests):
  {.fatal: "tests task not implemented, need nimbleutils".}

runTests(@["tests/test_grab.nim", "tests/test_grab_url_version.nim"], backends = {c, nims})

import std/osproc

discard execCmd("nim c tests/broken_test_readme.nim") # fails to compile the first time
runTests(@["tests/broken_test_readme.nim"], backends = {c, nims}) 
