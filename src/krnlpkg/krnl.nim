## Copyright 2024 Dean Hall See LICENSE for details
##
## KRNL
##

import armv7m/core
import plat, signal_registry, types

type Krnl = object
  sigReg: SignalRegistry[plat.platInterruptCount]
  actrReg: seq[pointer]

var k: Krnl

proc init*() =
  k.sigReg = newRegistry[plat.platInterruptCount]()

proc registerActor*(actrAddr: pointer) =
  # Temporary kernel-side adapter for the RegisterActor syscall path.
  # TODO: wire to full scheduler-backed actor registration.
  assert actrAddr != nil
  k.actrReg.add(actrAddr) # temporary stand-in

proc registerSignal*(sig: Signal) =
  k.sigReg.register(sig)

func runForever*() {.noreturn.} =
  while true:
    WFI()
