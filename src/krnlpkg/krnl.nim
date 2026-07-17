## Copyright 2024 Dean Hall See LICENSE for details
##
## KRNL
##

import armv7m/core
import actr_registry, plat, signal_registry, namespace, vectortable

type Krnl = object
  sigReg: SignalRegistry[plat.platIrqCnt]
  actrReg: ActrRegistry
  vectorTable: VectorTable[plat.platIrqCnt]

# One shared mutable reference set only by krnl.init()
var k: ptr Krnl

func init*(self: var Krnl) =
  k = self # this should be the ONLY place where k is set
  self.vectorTable.initVectorTable()

func registerActr*(self: var Krnl, actrAddr: pointer) =
  ## Register the actor with the kernel, give it an interrupt slot
  ## so it may be activated by pending an interrupt.
  ## Returns ... TBD
  # Temporary kernel-side adapter for the RegisterActor syscall path.
  assert actrAddr != nil
  let irqNmbr = self.vectorTable.getUnusedIrqNmbr()
  if irqNmbr == invalidIrqNmbr:
    # TODO: handle situation of too many actors, not enough interrupt slots
    return
  self.actrReg.registerActr(actrAddr, irqNmbr)
  self.vectorTable.setInterruptHandler(irqNmbr, dispatchIsr[irqNmbr])

func registerSignals*(self: var Krnl, nsHash: NamespaceHash32, maxSig: uint32): SigPubToken =
  ## Register a series of signals with the kernel.
  self.sigReg.registerSignals(nsHash, maxSig)

proc getActr*(irqNmbr: static IrqNmbr): ptr Actr {.inline.} =
  ## Returns a pointer to the actr registered with the given interrupt number
  ## ATTENTION: This procedure is called in the handler context
  k.actrReg.getActr(irqNmbr)

func runForever*() {.noreturn.} =
  while true:
    WFI()
