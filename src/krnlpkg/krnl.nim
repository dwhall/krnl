## Copyright 2024 Dean Hall See LICENSE for details
##
## KRNL
##

import armv7m/core

proc init*() =
  discard

func runForever*() {.noreturn.} =
  while true:
    WFI()
