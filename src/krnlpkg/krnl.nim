## Copyright 2024 Dean Hall See LICENSE for details
##
## KRNL
##

import std/math
import armv7m/[core, nvic, scb]
import plat, proj
import actr, namespace, signal_registry, vectortable

# TODO: armabi module?
type StackedFrame = object
  r0, r1, r2, r3, r12, lr, pc, xpsr: uint32

type Krnl* = object
  vectorTable: RamVectorTable
  sigReg: SignalRegistry
  actrReg: array[IrqNmbr, ptr Actr]

# The non-volatile Vector Table used at power-on-reset; from vector_table.c
let c_vectorTable {.importc: "c_vectorTable".}: VectorTable

## One shared mutable reference set only by krnl.init()
var k: ptr Krnl

proc initKrnl*(self: ptr Krnl) =
  ## Saves a reference to the Krnl and COPIES the non-vol vector table to RAM
  k = self # this should be the ONLY place where k is set
  k.vectorTable = c_vectorTable

proc switchToRamVectorTable*() =
  SCB.VTOR.write(cast[uint32](addr k.vectorTable))

proc exitPrivilegedMode*() =
  CONTROL.nPRIV(1)
  ISB()

proc dispatchIsrBody(
    frame: ptr StackedFrame, irqNmbr: IrqNmbr
) {.exportc: "dispatchIsrBody", noconv.} =
  ## Dispatches the actr's next event from its queue to its eventHandler
  ## and prepare the stackframe so that when we exit this ISR,
  ## we execute the actr's eventHandler with the proper arguments
  assert k.actrReg[irqNmbr] != nil, "Actr not registered"
  var actr = k.actrReg[irqNmbr]
  let evnt = actr[].popEvent()
  frame.r0 = cast[uint32](actr)
  frame.r1 = evnt.sig
  frame.r2 = evnt.val
  frame.lr = cast[uint32](proj.lowPowerRunForever)
  frame.pc = cast[uint32](actr.eventHandler)

proc dispatchIsr[irqNmbr: static IrqNmbr]() {.noconv, asmNoStackFrame.} =
  ## This isr MUST be placed directly in the vector table
  ## so that SP points at the stacked exception frame on entry
  ## before dispatchIsrBody() rewrites it.
  # irqNmbr is a `static` (compile-time) value, so we must use .emit
  # to splice it in as an immediate ("n" constraint)
  asm "mov r0, sp"
  {.emit: ["asm (\"mov r1, %0\"\n\t:\n\t: \"n\" (", irqNmbr, "));\n"].}
  asm """
    bl dispatchIsrBody
    ldr pc, =0xFFFFFFF9 // force exception return to Thread mode, use MSP
  """

# TODO:
# macro genDispatchIsrTable(): untyped =
#   ## Static table mapping each IrqNmbr to its dispatchIsr[N] proc.
#   ## Builds `[dispatchIsr[0], dispatchIsr[1], ..., dispatchIsr[high(IrqNmbr)]]`,
#   ## which instantiates dispatchIsr[N] for every valid IrqNmbr as a side effect.
#   result = newTree(nnkBracket)
#   for n in low(IrqNmbr).int .. high(IrqNmbr).int:
#     result.add newTree(nnkBracketExpr, ident"dispatchIsr", newLit(uint8 n))
#
# const dispatchIsrTable: array[IrqNmbr, proc()] = [
const dispatchIsrTable =
  [dispatchIsr[0], dispatchIsr[1], dispatchIsr[2], dispatchIsr[3]]

proc enableIrq(irqNmbr: IrqNmbr) =
  ## Clears any pending interrupt and enables it
  let (regIdx, bitIdx) = divmod(irqNmbr.uint32, 32)
  case regIdx
  of 0:
    NVIC.NVIC_ICPR(0).read().CLRPEND(bitIdx, 1).write()
    NVIC.NVIC_ISER(0).read().SETENA(bitIdx, 1).write()
  of 1:
    NVIC.NVIC_ICPR(1).read().CLRPEND(bitIdx, 1).write()
    NVIC.NVIC_ISER(1).read().SETENA(bitIdx, 1).write()
  else:
    assert irqNmbr < 64, "Fill in more cases"

proc default_Handler() {.importc: "default_Handler", noconv.}

proc registerSignals*(nsHash: NamespaceHash32, maxSig: uint32): SigPubToken =
  ## Register a series of signals with the kernel.
  k.sigReg.registerSignals(nsHash, maxSig)

proc registerIrqHandler*(irqNmbr: IrqNmbr, irqHandler: IrqHandler) =
  ## Sets the handler in the RAM vector table and enables the interrupt
  k.vectorTable.setIrqHandler(irqNmbr, irqHandler)
  enableIrq(irqNmbr)

proc registerActr*(actr: ptr Actr) =
  ## Register the actor with the kernel, give it an interrupt slot
  ## so it may be activated by pending an interrupt.
  ## Returns ... TBD
  # Temporary kernel-side adapter for the RegisterActor syscall path.
  assert actr != nil
  let findResult = k.vectorTable.findIrqHandler(default_Handler)
  if findResult < 0:
    # TODO: ERROR: too many actors, not enough interrupt slots
    return
  let irqNmbr = IrqNmbr(findResult)
  actr[].setIrqNmbr(irqNmbr)
  k.actrReg[irqNmbr] = actr
  let dispatchIsr = dispatchIsrTable[irqNmbr.int]
  registerIrqHandler(irqNmbr, dispatchIsr)
