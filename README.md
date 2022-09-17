# grab

Adds a `grab` statement for installing and importing Nimble packages
directly through Nim code, similar to Groovy's Grape and `@Grab`. Works
with NimScript, as all the computation is done at compile time.

This installs the package globally, and can affect compilation time. For
this reason it should generally only be used for scripts, tests, snippets and
the like.

```nim
import grab

# install the package `regex` if not installed already, and import it
grab "regex"

assert "abc.123".match(re"\w+\.\d+")

# run install command with the given arguments
grab package("-y https://github.com/arnetheduck/nim-result@#HEAD",
             name = "result", forceInstall = true): # clarify package name to correctly query path
  # imports from the package directory
  import results

func works(): Result[int, string] =
  result.ok(123)

func fails(): Result[int, string] =
  result.err("abc")

assert works().isOk
assert fails().error == "abc"
```

Install with:

```
nimble install grab
```
