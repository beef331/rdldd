task installPackage, "Installs the package":
  selfExec("c -d:release librdldd.nim")
  exec("sudo mv librdldd.so /usr/lib64/")
  selfExec("c -d:release rdldd.nim")
  exec("sudo mv rdldd /usr/bin/")
