import grab

grab "-Y https://github.com/metagn/sliceutils@0.2.0"

block: # check if we are on exactly sliceutils version 0.2.0
  doAssert declared(sliceutils.MultiSlice)
