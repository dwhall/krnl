## Copyright 2026 Dean Hall See LICENSE for details
#!fmt: off

when defined(debug):
  {.passc: "-Ideps/RTT/RTT".}
  {.passc: "-Ideps/RTT/Config".}
  {.compile: "deps/RTT/RTT/SEGGER_RTT.c".}
  {.compile: "deps/RTT/RTT/SEGGER_RTT_printf.c".}

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

