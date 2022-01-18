## Adds a `grab` statement for installing and importing Nimble packages
## directly through code.
## 
## Works with NimScript.

runnableExamples:
  import grab

  grab "regex"

  assert "abc.123".match(re"\w+\.\d+")

  grab package("-y https://github.com/arnetheduck/nim-result@#HEAD",
               name = "result", forceInstall = true):
    import results

  func works(): Result[int, string] =
    result.ok(123)

  func fails(): Result[int, string] =
    result.err("abc")
  
  assert works().isOk
  assert fails().error == "abc"

import macros, strutils, os

when not compiles (var x = ""; x.delete(0 .. 0)):
  template delete(x: untyped, s: HSlice): untyped =
    let y = s
    x.delete(y.a, y.b)

proc stripLeft(package: var string) =
  package.delete(0 .. max(max(package.rfind('/'), package.rfind('\\')), package.rfind(' ')))

proc stripRight(package: var string) =
  template minim(a, b) =
    let c = b
    if a < 0 or c < a: a = c
  var len = package.find('?')
  len.minim(package.find('@'))
  if len < 0: len = package.len
  package.setLen(len)

proc parseName(package: string): string =
  result = package
  stripLeft(result)
  stripRight(result)

proc extractWithVersion(package: string): string =
  result = package
  stripLeft(result)
  var f = result.find('@')
  if f < 0: f = result.len
  var s = result.find('?')
  if s < 0: s = result.len + 1
  if s <= f: result.delete(s .. f)

type Package* = object
  ## Package information to be used when installing and importing packages.
  name*, installCommand*, pathQuery*: string
  forceInstall*: bool

proc package*(installCommand, name, pathQuery: string, forceInstall = false): Package =
  ## Generates package information with arguments to a `nimble install`
  ## command, package name, and optionally a name and version pair
  ## for the purpose of querying the module path.
  Package(installCommand: installCommand,
    name: parseName(name),
    pathQuery: pathQuery,
    forceInstall: forceInstall)

proc package*(installCommand, name: string, forceInstall = false): Package =
  ## Generates package information with arguments to a `nimble install`
  ## command and a package name (optionally with a version).
  Package(installCommand: installCommand,
    name: parseName(name),
    pathQuery: name,
    forceInstall: forceInstall)

proc package*(installCommand: string, forceInstall = false): Package =
  ## Converts the arguments of a `nimble install` command into
  ## package information.
  ## 
  ## If the name of the package is different from the one assumed from
  ## the install command, then the package cannot be imported. In this case,
  ## a name or name and version pair must be given, such as
  ## ``package("fakename", "realname@0.1.0")``.
  Package(installCommand: installCommand,
    pathQuery: extractWithVersion(installCommand),
    name: parseName(installCommand),
    forceInstall: forceInstall)

proc getPath(package: Package): string =
  for line in staticExec("nimble path " & package.pathQuery).splitLines:
    if line.len != 0:
      result = line

proc grabImpl(package: Package, imports: NimNode): NimNode =
  when defined(grabGiveHint):
    hint("grabbing: " & $package, imports)

  let doPath = package.pathQuery.len != 0
  let doInstall = package.forceInstall or
    (doPath and not dirExists(getPath(package)))

  if doInstall:
    let installOutput = staticExec("nimble install " &
      (if package.forceInstall: "-Y " else: "-N ") &
      package.installCommand)
    if "Error: " in installOutput:
      error("could not install " & package.name & ", install log:\p" &
        installOutput, imports)

  let imports =
    if imports.len != 0:
      imports
    else:
      let x = ident(package.name)
      x.copyLineInfo(imports)
      newStmtList(newTree(nnkImportStmt, x))

  let path = if doPath: getPath(package) else: ""
  if doPath and not dirExists(path):
    error("could not locate " & package.pathQuery & ", got error or invalid path:\p" &
      path, imports)

  proc patchImport(p: string, n: NimNode): NimNode =
    var root = n
    const replaceKinds = {nnkStrLit..nnkTripleStrLit, nnkIdent, nnkSym, nnkAccQuoted}
    proc replace(s: NimNode): NimNode =
      if p.len != 0:
        var str = (p / $s)
        if not str.endsWith(".nim"):
          str.add(".nim")
        newLit(str)
      else:
        s
    if root.kind in replaceKinds:
      replace root
    else:
      while root.len != 0:
        let index = if root.kind in {nnkCommand..nnkPostfix}: 1 else: 0
        if root[index].kind in replaceKinds:
          root[index] = replace root[index]
          break
        else:
          root = root[index]
      n

  result = copy imports
  for imp in result:
    case imp.kind
    of nnkImportStmt:
      for i in 0 ..< imp.len:
        imp[i] = patchImport(path, imp[i])
    of nnkImportExceptStmt, nnkFromStmt, nnkIncludeStmt:
      imp[0] = patchImport(path, imp[0])
    else: discard

macro grab*(package: static Package, imports: untyped) =
  ## Installs a package with Nimble and immediately imports it.
  ## 
  ## Can be followed with a list of imports from the package in an indented
  ## block. Imports outside this block will not work. By default, only
  ## the main module of the package is imported.
  ## 
  ## This installs the package globally, and can fairly affect compilation time.
  ## For this reason it should only be used for scripts and snippets and the like.
  ## 
  ## If the package is already installed, it will not reinstall it.
  ## This can be overriden by adding `-Y` at the start of the install command.
  ## 
  ## See module documentation for usage.
  result = grabImpl(package, imports)

macro grab*(installCommand: static string, imports: untyped) =
  ## Shorthand for `grab(package(installCommand), imports)`.
  ## 
  ## See module documentation for usage.
  result = grabImpl(package(installCommand), imports)

macro grab*(package) =
  ## Calls `grab(package, imports)` with the main module
  ## deduced from the package name imported by default.
  let imports = newNilLit()
  imports.copyLineInfo(package)
  let grabCall = ident("grab")
  grabCall.copyLineInfo(package)
  result = newCall(grabCall, package, imports)
  result.copyLineInfo(package)
