import grab

grab "assigns"

block: # test assigns
  (a, (b, c)) := (1, (2, 3))
  doAssert (a, b, c) == (1, 2, 3)
