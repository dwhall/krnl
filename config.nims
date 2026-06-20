import std/[os, strutils]

task test, "run unit tests":
  for testFile in listFiles("tests/"):
    if testFile.endsWith(".nim") and testFile.splitPath.tail.startsWith("t"):
      echo "TEST: ", testFile
      exec("nim c -r --skipParentCfg " & testFile)
