## Copyright 2026 Dean Hall See LICENSE for details
##
## KRNL Event value type
##
## This MUST be defined once for the project and remain immutable

const projEventValueSelector {.strdefine.}: string = "uint32"

when projEventValueSelector == "uint32":
  type EventValue* = uint32
else:
  {.error: "Invalid projEventValueSelector".}
