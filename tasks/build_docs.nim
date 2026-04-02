when (NimMajor, NimMinor) >= (1, 4):
  when (compiles do: import nimbleutils):
    import nimbleutils
    # https://github.com/metagn/nimbleutils

when not declared(buildDocs):
  {.fatal: "docs task not implemented, need nimbleutils".}

buildDocs(gitUrl = "https://github.com/metagn/grab")
