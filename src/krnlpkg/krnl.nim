## Copyright 2024 Dean Hall See LICENSE for details
##
## KRNL
##

import armv7m/core
import plat, signal_registry, types, namespace

type Krnl = object
  sigReg: SignalRegistry[plat.platInterruptCount]
  actrReg: seq[pointer]

var k: Krnl

proc init*() =
  k.sigReg = newRegistry[plat.platInterruptCount]()

proc registerActor*(actrAddr: pointer) =
  ## Register the actor with the kernel, give it an interrupt slot
  ## so it may be activated by pending an interrupt.
  ## Returns ... TBD
  # Temporary kernel-side adapter for the RegisterActor syscall path.
  assert actrAddr != nil
  k.actrReg.add(actrAddr) # temporary

proc registerSignals*(nsHash: NamespaceHash, maxSigEnum: uint32): SigPubToken =
  ## Register a series of signals with the kernel.
  ## Returns a token granting access to publish the signals
  k.sigReg.register(nsHash, maxSigEnum)

func runForever*() {.noreturn.} =
  while true:
    WFI()
