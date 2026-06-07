## Copyright 2026 Dean Hall See LICENSE for details
#!fmt: off

# Third party, pathX, is needed here as explained here: https://forum.nim-lang.org/t/13965
import pathX

type 
  BuildAbsFile = PathX[fdFile, arAbso, BuildOS, true]
  BuildRelDir = PathX[fdDire, arRela, BuildOS, true]
  BuildRelFile = PathX[fdFile, arRela, BuildOS, true]

when defined(debug):
  const 
    csp = BuildAbsFile(currentSourcePath())
    krnlDir = csp.parentDir().parentDir().parentDir()
    rttDir = krnlDir / BuildRelDir"deps" / BuildRelDir"RTT"
  {.passC: "-I" & string(rttDir / BuildRelDir"RTT").}
  {.passC: "-I" & string(rttDir / BuildRelDir"Config").}
  {.compile: rttDir / BuildRelDir"RTT" / BuildRelFile"SEGGER_RTT.c".}
  {.compile: rttDir / BuildRelDir"RTT" / BuildRelFile"SEGGER_RTT_printf.c".}

  # Direct bindings to SEGGER RTT functions
  proc initRTT*() {.importc: "SEGGER_RTT_Init", header: "SEGGER_RTT.h"}
  proc debugRTTwrite*(bufferIndex: cint, s: cstring, len: cint): cuint {.importc: "SEGGER_RTT_Write", header: "SEGGER_RTT.h".}
  proc debugRTTwriteStr*(bufferIndex: cint, s: cstring): cuint {.importc: "SEGGER_RTT_WriteString", header: "SEGGER_RTT.h".}
  proc debugRTTprintf*(bufferIndex: cint, format: cstring) {.importc: "SEGGER_RTT_printf", varargs, header: "SEGGER_RTT.h".}

  # Idiomatic Nim wrappers
  proc debugPrint*(s: string, idx = 0) =
    discard debugRTTwriteStr(idx.cint, s.cstring)
  proc debugPrint*(buf: openArray[char], idx = 0) =
    discard debugRTTwrite(idx.cint, cast[cstring](addr buf[0]), buf.len)

else:
  # Stubs for release builds
  proc initRTT*() {.inline.} = discard
  proc debugRTTwrite*(bufferIndex: cint, s: cstring, len: cint): cuint {.inline.} = discard
  proc debugRTTwriteStr*(bufferIndex: cint, s: cstring): cuint {.inline.} = discard
  proc debugRTTprintf*(bufferIndex: cint, format: cstring) {.inline, varargs.} = discard
  proc debugPrint*(s: string, idx: cint = 0) = discard
  proc debugPrint*(buf: openArray[char], idx: cint = 0) = discard























