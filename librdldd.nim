## Lib we make to inject our own dlopen into a program to print the logs
import std/[os, strutils, locks]

type
  Info = object
    theAddr: pointer
    name: cstring
    headers: pointer
    nums: int
    dlpiAdds: uint
    dlpiSubs: uint
    dlpiTlsModId: uint
    tlsData: pointer
  Callback = proc(_: ptr Info, size: int, data: pointer): int32 {.cdecl.}

proc iteratePhdr(cb: Callback, data: pointer): int32 {.importc: "dl_iterate_phdr", cdecl.}

proc dlsym(lib: pointer, name: cstring): pointer {.importc.}

var
  realDlOpen: proc(_: cstring, flags: int32): pointer {.cdecl.}
  file = open(getEnv("RDLDD_PATH", "/tmp/rdldd"), fmWrite)

proc NimMain(){.cdecl, importc.}

proc dlopen(name: cstring, flags: cint): pointer {.cdecl, exportc, dynlib.} =
  result = realDlOpen(name, flags)
  if result != nil and name.len > 0:
    file.writeLine name
    file.flushFile()

proc callBack(info: ptr Info, size: int, data: pointer): int32 {.cdecl.} =
  if info.name != nil and info.name.len > 0:
    let name = $info.name
    if not name.endsWith"librdldd.so":
      file.writeLine info.name
      file.flushFile()

proc init() {.codegendecl:"__attribute__ ((constructor)) $# $#$#", cdecl, exportc, dynlib.} =
  realDlOpen = cast[typeof(realDlOpen)](dlSym(cast[pointer](-1), "dlopen"))
  NimMain()
  discard iteratePhdr(callBack, nil)

proc deinit() {.codegendecl:"__attribute__ ((destructor)) $# $#$#", cdecl, exportc, dynlib.} =
  file.close()
