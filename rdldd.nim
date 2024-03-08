## CLI program that we use to inject `lbrdldd` and get a nice output
import std/[osproc, strtabs, os, parseopt, strutils, selectors, monotimes, times]
import shared

proc main(program: string, bufferPath: string, timeout: int) =
  removeFile(bufferPath)
  setCurrentDir(program.expandTilde.parentDir)
  createNamedPipe(bufferPath, {RUser, WUser})
  let
    process = startProcess(
      program.expandTilde,
      env = newStringTable({
        "LD_PRELOAD": "librdldd.so",
        "RDLDD_PATH": bufferPath}
      ),
      options = {poUsePath, poStdErrToStdOut, poDaemon}
    )
  let theFile = open(bufferPath, fmRead)
  defer: theFile.close()
  defer: process.close()

  if timeout > 0:
    let sel = newSelector[int]()
    defer: sel.close()
    sel.registerHandle(theFile.getFileHandle(), {Read}, 0)

    var start = getMonoTime()
    while (let keys = sel.select(100); true):
      for key in keys:
        echo theFile.readLine()

      if getMonoTime() - start >= initDuration(milliseconds = timeOut):
        break

  else:
    while not theFile.endOfFile():
      echo theFile.readLine()

  try:
    process.kill()
  except:
    discard




proc writeHelp =
  echo """
This is a really dumb verions of ldd.
What this does is use a shim '.so' to replace 'dlopen'.
Enabling you to see what libraries a program uses.
usage:
rdldd [options] program

-h, --help Shows this message.
-b, --bufferPath Where the program writes it's intermediate buffer.
-t, --timeout How long to wait after a program starts to stop it.
"""


proc parseIt() =
  var p = initOptParser(commandLineParams()[0..^1])

  var
    program = ""
    buffer = "/tmp/rdldd"
    timeout = 1000

  for kind, key, val in p.getopt():
    case kind
    of cmdArgument:
      if program != "":
        echo "Attempted to provide target twice"
      program = key
    of cmdLongOption, cmdShortOption:
      case key
      of "b", "buffer":
        buffer = val
      of "t", "timeout":
        timeout =
          try:
            parseInt(val)
          except:
            echo "Expected a valid integer for timeout"
            return
      of "h", "help":
        writeHelp()
        return

    of cmdEnd: assert(false) # cannot happen

  if program == "":
    writeHelp()
  else:
    main(program, buffer, timeout)

parseIt()
