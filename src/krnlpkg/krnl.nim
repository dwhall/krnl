## Copyright 2024 Dean Hall See LICENSE for details
##
## KRNL
##

import armv7m/core
import actr_registry, plat, signal_registry, types, namespace

type Krnl = object
  sigReg: SignalRegistry[plat.platInterruptCount]
  actrReg: ActrRegistry
  # TODO: vector table

var k: Krnl

proc init*() =
  const timerInterval = 3277 # ~100 ms
  # TODO: configureTimer(timerInterval, timerCallback)

proc registerActr*(actrAddr: pointer) =
  ## Register the actor with the kernel, give it an interrupt slot
  ## so it may be activated by pending an interrupt.
  ## Returns ... TBD
  # Temporary kernel-side adapter for the RegisterActr syscall path.
  assert actrAddr != nil
  let irqNmbr = InterruptNmbr(0) # TODO: get irqNmbr from VectorTable
  k.actrReg.registerActr(actrAddr, irqNmbr) # temporary

proc registerSignals*(nsHash: NamespaceHash, maxSig: uint32): auto =
  ## Register a series of signals with the kernel.
  ## Returns a token granting access to publish the signals
  k.sigReg.registerSignals(nsHash, maxSig)

func runForever*() {.noreturn.} =
  while true:
    WFI()
