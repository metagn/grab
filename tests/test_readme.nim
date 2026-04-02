import grab

# install the package `regex` if not installed already, and import it
grab "regex"

assert "abc.123".match(re"\w+\.\d+")

# run install command with the given arguments
grab package("-y https://github.com/arnetheduck/nim-result@#HEAD",
             name = "results", forceInstall = true): # clarify package name to correctly query path
  # imports from the package directory
  import results

func works(): Result[int, string] =
  result.ok(123)

func fails(): Result[int, string] =
  result.err("abc")

assert works().isOk
assert fails().error == "abc"
