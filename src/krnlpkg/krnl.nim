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

proc registerActor*(actrAddr: pointer): uint32 =
  ## Register the actor with the kernel, give it an interrupt slot
  ## so it may be activated by pending an interrupt.
  ## Returns ... TBD
  # Temporary kernel-side adapter for the RegisterActor syscall path.
  assert actrAddr != nil
  k.actrReg.add(actrAddr) # temporary
  result = 0'u32 # temporary type and value

proc registerSignal*(sig: Signal): uint32 =
  ## Register the signal with the kernel
  ## Returns ... TBD
  k.sigReg.register(sig)
  result = 0'u32 # temporary type and value

func runForever*() {.noreturn.} =
  while true:
    WFI()
