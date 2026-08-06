## Copyright 2024 Dean Hall See LICENSE for details
##
## KRNL
##

import std/macros
import armv7m/core
import actr, actr_registry, irqnmbr, namespace, signal_registry, vectortable

type Krnl* = object
  sigReg: SignalRegistry
  actrReg: ActrRegistry
  vectorTable: VectorTable

## One shared mutable reference set only by krnl.init()
var k: ptr Krnl

proc init*(self: var Krnl) =
  k = addr self # this should be the ONLY place where k is set
  self.vectorTable.initVectorTable()

proc dispatchIsr*[N: static IrqNmbr]() = #{.asmNoStackFrame.} =
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
  var actr = k.actrReg.getActr(N)
  let evnt = actr.popEvent()
  when defined(arm):
    asm """
      mov r0, %0
      mov r1, %1
      mov r2, %2
      mov lr, %3
      ldr pc, =0xFFFFFFF9 // return from exception, use MSP after return
      :
      : "r"(`actr`), "r"(`evnt`.sig), "r"(`evnt`.val), "r"(`actr`->eventHandler)
      : "r0", "r1", "r2", "memory"
    """
  else:
    discard actr.eventHandler(actr, evnt.sig, evnt.val)

macro genDispatchIsrTable(): untyped =
  ## Builds `[dispatchIsr[0], dispatchIsr[1], ..., dispatchIsr[high(IrqNmbr)]]`,
  ## which instantiates dispatchIsr[N] for every valid IrqNmbr as a side effect.
  result = newTree(nnkBracket)
  for n in low(IrqNmbr).int .. high(IrqNmbr).int:
    result.add newTree(nnkBracketExpr, ident"dispatchIsr", newLit(uint8 n))

# const dispatchIsrTable: array[IrqNmbr, proc()] = [
const dispatchIsrTable = [
  dispatchIsr[IrqNmbr(0)],
  dispatchIsr[IrqNmbr(1)],
  dispatchIsr[IrqNmbr(2)],
  dispatchIsr[IrqNmbr(3)],
]
  # TODO: genDispatchIsrTable()
  ## Static table mapping each IrqNmbr to its dispatchIsr[N] proc.

proc registerActr*(actr: Actr) =
  ## Register the actor with the kernel, give it an interrupt slot
  ## so it may be activated by pending an interrupt.
  ## Returns ... TBD
  # Temporary kernel-side adapter for the RegisterActor syscall path.
  assert actr != nil
  let irqNmbr = k.vectorTable.getUnusedIrqNmbr()
  if irqNmbr == invalidIrqNmbr:
    # TODO: ERROR: too many actors, not enough interrupt slots
    return
  k.actrReg.registerActr(actr, irqNmbr)
  let dispatchIsr = dispatchIsrTable[irqNmbr.int]
  k.vectorTable.setIrqHandler(irqNmbr, dispatchIsr)

proc registerSignals*(nsHash: NamespaceHash32, maxSig: uint32): SigPubToken =
  ## Register a series of signals with the kernel.
  k.sigReg.registerSignals(nsHash, maxSig)

func runForever*() {.noreturn.} =
  while true:
    WFI()
