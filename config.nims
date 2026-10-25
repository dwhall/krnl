import std/[os, strutils]

task test, "run unit tests":
  for testFile in listFiles("tests/"):
    # NimScript's splitPath only splits on '/', but listFiles gives '\' on Windows
    let fileName = testFile.replace('\\', '/').splitPath.tail
    if fileName.endsWith(".nim") and fileName.startsWith("test_"):
      echo "TEST: ", testFile
      exec("nim c -r --skipParentCfg " & testFile)

  # Modules that MUST fail to compile, with the error message expected from each
  const compileFailTests = [
    ("tests/actr_copy_prevent.nim", "'=copy' is not available for type <Actr>")
  ]
  for (testFile, expectedErr) in compileFailTests:
    echo "COMPILE-FAIL TEST: ", testFile
    let (output, exitCode) =
      gorgeEx("nim c --skipParentCfg --hints:off " & thisDir() / testFile)
    if exitCode == 0 or expectedErr notin output:
      echo output
      quit("FAILED: " & testFile & " expected compile error: " & expectedErr)
