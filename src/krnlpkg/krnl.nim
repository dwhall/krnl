## Copyright 2024 Dean Hall See LICENSE for details
##
## KRNL
##

import armv7m/core
import actr_registry, plat, signal_registry, namespace, vectortable

type Krnl = object
  sigReg: SignalRegistry[plat.platIrqCnt]
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
  # Temporary kernel-side adapter for the RegisterActor syscall path.
  assert actrAddr != nil
  let irqNmbr = IrqNmbr(0) # TODO: get irqNmbr from VectorTable
  k.actrReg.registerActr(actrAddr, irqNmbr) # temporary

proc registerSignals*(nsHash: NamespaceHash32, maxSig: uint32): SigPubToken =
  ## Register a series of signals with the kernel.
  k.sigReg.registerSignals(nsHash, maxSig)

func runForever*() {.noreturn.} =
  while true:
    WFI()
