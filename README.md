# grab

A library for installing and importing Nimble packages directly through
Nim code, similar to Groovy's Grape and `@Grab`. Works with NimScript,
as all the computation is done at compile time.

```nim
import grab

# install the package `regex` if not installed already, and import it
grab "regex"

assert "abc.123".match(re"\w+\.\d+")

# run install command with the given arguments (default behavior for string argument as above)
grab package(installCommand = "-Y https://github.com/arnetheduck/nim-result@#HEAD",
             name = "result"): # clarify package name
  # custom imports from the package directory
  results

func works(): Result[int, string] =
  result.ok(123)

func fails(): Result[int, string] =
  result.err("abc")

assert works().isOk
assert fails().error == "abc"
```
