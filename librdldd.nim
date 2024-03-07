## Lib we make to inject our own dlopen into a program to print the logs
import std/[os, sets]

proc dlsym(lib: pointer, name: cstring): pointer {.importc.}

var
  realDlOpen: proc(_: cstring, flags: int32): pointer {.cdecl.}
  buffer: string
  found: HashSet[string]

proc NimMain(){.cdecl, importc.}

proc dlopen(name: cstring, flags: cint): pointer {.cdecl, exportc, dynlib.} =
  result = realDlOpen(name, flags)
  if result != nil and name.len > 0:
    let name = $name
    if name notin found:
      buffer.add name
      buffer.add "\n"
      found.incl name


proc init() {.codegendecl:"__attribute__ ((constructor)) $# $#$#", cdecl, exportc, dynlib.} =
  realDlOpen = cast[typeof(realDlOpen)](dlSym(cast[pointer](-1), "dlopen"))
  NimMain()

proc close() {.codegendecl:"__attribute__ ((destructor)) $# $#$#", cdecl, exportc, dynlib.} =
  writeFile(getEnv("RDLDD_PATH"), buffer)



