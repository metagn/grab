## A module for installing and importing Nimble packages directly through code.
## 
## Works with NimScript.

runnableExamples:
  import grab

  grab "regex"

  assert "abc.123".match(re"\w+\.\d+")

  grab package("-Y https://github.com/arnetheduck/nim-result@#HEAD",
               name = "result"):
    results

  func works(): Result[int, string] =
    result.ok(42)

  func fails(): Result[int, string] =
    result.err("bad luck")
  
  assert works().isOk
  assert fails().error == "bad luck"

import macros, strutils, os

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

proc package*(installCommand, name, pathQuery: string): Package =
  ## Generates package information with arguments to a `nimble install`
  ## command, package name, and optionally a name and version pair
  ## for the purpose of querying the module path.
  Package(installCommand: installCommand,
    name: parseName(name),
    pathQuery: pathQuery)

proc package*(installCommand, name: string): Package =
  ## Generates package information with arguments to a `nimble install`
  ## command and a package name (optionally with a version).
  Package(installCommand: installCommand,
    name: parseName(name),
    pathQuery: name)

proc package*(installCommand: string): Package =
  ## Converts the arguments of a `nimble install` command into
  ## package information.
  ## 
  ## If the name of the package is different from the one assumed from
  ## the install command, then the package cannot be imported. In this case,
  ## a name or name and version pair must be given, such as
  ## ``package("fakename", "realname@0.1.0")``.
  Package(installCommand: installCommand,
    pathQuery: extractWithVersion(installCommand),
    name: parseName(installCommand))

proc grabImpl(package: Package, imports: NimNode): NimNode =
  when defined(grabGiveHint):
    hint("grabbing: " & package, imports)

  let installOutput = staticExec("nimble install -N " & package.installCommand)
  if "Error: " in installOutput:
    error("could not install " & package.name & ", install log:\p" &
      installOutput, imports)

  let imports =
    if imports.len != 0:
      imports
    else:
      let x = ident(package.name)
      x.copyLineInfo(imports)
      newPar(x)

  proc doImport(p: string, n: NimNode, res: NimNode) =
    case n.kind
    of nnkPar, nnkBracket, nnkCurly, nnkStmtList, nnkStmtListExpr:
      for a in n:
        doImport(p, a, res)
    else:
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
        res.add(replace root)
      else:
        while root.len != 0:
          let index = if root.kind in {nnkCommand..nnkPostfix}: 1 else: 0
          if root[index].kind in replaceKinds:
            root[index] = replace root[index]
            break
          else:
            root = root[index]
        res.add(n)

  let path = staticExec("nimble path " & package.pathQuery).strip
  if "Error: " in path:
    error("could not get path of " & package.pathQuery & ", got error:\p" &
      path, imports)

  result = newNimNode(nnkImportStmt, imports)
  for n in imports:
    doImport(path, n, result)

macro grab*(package: static Package, imports: varargs[untyped]) =
  ## Installs a package with Nimble and immediately imports it.
  ## 
  ## Can be followed with a list of custom imports from the package.
  ## This can also be an indented block.
  ## 
  ## If the package is already installed, it will not reinstall it.
  ## This can be overriden by adding `-Y` at the start of the install command.
  ## 
  ## See module documentation for usage.
  let package = package
  result = grabImpl(package, imports)

macro grab*(installCommand: static string, imports: varargs[untyped]) =
  ## Shorthand for `grab(package(installCommand), imports)`.
  ## 
  ## See module documentation for usage.
  let installCommand = installCommand
  result = grabImpl(package(installCommand), imports)
