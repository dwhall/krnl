## Copyright 2024 Dean Hall See LICENSE for details
##
## KRNL
##

import armv7m/core
import actr, actr_registry, irqnmbr, namespace, plat, signal_registry, vectortable

type Krnl = object
  sigReg: SignalRegistry
  actrReg: ActrRegistry
  vectorTable: VectorTable

## One shared mutable reference set only by krnl.init()
var k: ptr Krnl

proc init*(self: var Krnl) =
  k = addr self # this should be the ONLY place where k is set
  self.vectorTable.initVectorTable()

proc dispatchIsr[N: static IrqNmbr]() {.asmNoStackFrame.} =
  ## Dispatches the actr's next event to the actr with irqNmbr N.
  ## ATTENTION: This procedure is called in the handler context
  ## This procedure's only use is to be placed in the vector table.
  #[
    B1.5.8 Exception return behavior
    An exception return occurs when the processor is in Handler mode and
    one of the following instructions loads a value of 0xFXXXXXXX into the PC:
    * POP/LDM that includes loading the PC.
    * LDR with PC as a destination.
    * BX with any register.
  ]#
  let
    actr = k.actrReg.getActr(N)
    evnt = actr.popEvent()
    handler = actr.eventHandler
  when defined(arm):
    asm """
      mov r0, %0
      mov r1, %1
      mov lr, %2
      ldr pc, #0xF0000000 ; return from exception
      :
      : "r"(`actr`), "r"(`evnt`), "r"(`handler`)
      : "r0", "r1", "memory"
    """
  else:
    discard handler(actr, evnt)

func registerActr*(self: var Krnl, actr: var Actr) =
  ## Register the actor with the kernel, give it an interrupt slot
  ## so it may be activated by pending an interrupt.
  ## Returns ... TBD
  # Temporary kernel-side adapter for the RegisterActor syscall path.
  assert actr != nil
  let irqNmbr = self.vectorTable.getUnusedIrqNmbr()
  if irqNmbr == invalidIrqNmbr:
    # TODO: handle situation of too many actors, not enough interrupt slots
    return
  self.actrReg.registerActr(actr, irqNmbr)
  self.vectorTable.setIrqHandler(irqNmbr, dispatchIsr[irqNmbr])

func registerSignals*(
    self: var Krnl, nsHash: NamespaceHash32, maxSig: uint32
): SigPubToken =
  ## Register a series of signals with the kernel.
  self.sigReg.registerSignals(nsHash, maxSig)

func runForever*() {.noreturn.} =
  while true:
    WFI()
