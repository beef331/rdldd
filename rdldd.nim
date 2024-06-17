## CLI program that we use to inject `lbrdldd` and get a nice output
import std/[osproc, strtabs, os, parseopt, strutils, selectors, monotimes, times, sets]
import shared

const defaultTimeout = 100

proc main(program: string, bufferPath: string, timeout: int, showOut: bool) =
  removeFile(bufferPath)
  let currDir = getCurrentDir()
  if not program.isRelativeTo(currDir):
    setCurrentDir(program.expandTilde.parentDir)
  createNamedPipe(bufferPath, {RUser, WUser})
  let
    flags = block:
      var flags = {poUsePath, poDaemon}
      if showOut:
        flags.incl poParentStreams
      flags
    process =
      try:
        startProcess(
          program.expandTilde,
          env = newStringTable({
            "LD_PRELOAD": "librdldd.so",
            "RDLDD_PATH": bufferPath}
          ),
          options = flags)
      except CatchableError as e:
        echo "Could not start program: " & e.msg
        return

  let theFile = open(bufferPath, fmRead)
  defer:
    theFile.close()
    process.close()

  var printed: HashSet[string]
  if timeout > 0:
    let sel = newSelector[int]()
    defer: sel.close()
    sel.registerHandle(theFile.getFileHandle(), {Read}, 0)

    var start = getMonoTime()
    while (let keys = sel.select(100); true):
      for key in keys:
        try:
          let lib = theFile.readLine()
          if lib notin printed:
            echo lib
            printed.incl lib
        except:
          discard

      if getMonoTime() - start >= initDuration(milliseconds = timeOut):
        break

  else:
    while not theFile.endOfFile():
      let lib = theFile.readLine()
      if lib notin printed:
        echo lib
        printed.incl lib

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
-t, --timeout How long to wait after a program starts to stop it (default: $#).
-s, --stdout Write the stdout of the program
""" % [$defaultTimeout]


proc parseIt() =
  var p = initOptParser(commandLineParams()[0..^1])

  var
    program = ""
    buffer = "/tmp/rdldd"
    timeout = defaultTimeout
    showOut = false

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
      of "s", "stdout":
        showOut = true

    of cmdEnd: assert(false) # cannot happen

  if program == "":
    writeHelp()
  else:
    main(program, buffer, timeout, showOut)

parseIt()
