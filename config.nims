import std/strutils

const
  is32Bit = not hostOs.contains("64") # Is this how we do this?
  libPath =
    when is32Bit:
      "/usr/lib32/"
    else:
      "/usr/lib64/"

when defined(nimble):
  before install:
    selfExec("c -d:release librdldd.nim")
    exec "sudo mv librdldd.so " & libPath
else:
  task installPackage, "Installs the package":
    selfExec("c -d:release librdldd.nim")
    exec("sudo mv librdldd.so /usr/lib64/")
    selfExec("c -d:release rdldd.nim")
    exec("sudo mv rdldd /usr/bin/")

  task installDebug, "Installs the package":
    selfExec("c -d:debug librdldd.nim")
    exec("sudo mv librdldd.so /usr/lib64/")
    selfExec("c -d:debug rdldd.nim")
    exec("sudo mv rdldd /usr/bin/")
