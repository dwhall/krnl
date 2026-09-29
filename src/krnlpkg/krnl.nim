## Copyright 2024 Dean Hall See LICENSE for details
##
## KRNL
##

import std/[math, volatile]
import armv7m/[core, nvic, scb]
import plat, proj
import actr, namespace, signal_registry, vectortable

type Krnl* = object
  vectorTable: RamVectorTable
  sigReg: SignalRegistry
  actrReg: array[IrqNmbr, ptr Actr]

# TODO: armabi module?
type StackedFrame = object
  r0, r1, r2, r3, r12, lr, pc, xpsr: uint32

type NvicPriority = uint8 # 0 is the highest priority
converter toNvicPriority*(prio: ActrPriority): NvicPriority =
  ## Converts ActrPriority where 0 is the lowest priority
  ## to NvicPriority where 0 is the highest priority
  NvicPriority(
    ((0xFF'u32 shr plat.nvicPriorityBits()) + 1'u32 - prio.uint32) shl
      plat.nvicPriorityBits()
  )

const
  # Actr interrupt priorities must never be more urgent than a dev
  # so that an actr's dispatchIsr always tail-chains after a device ISR
  # (which may post() to it) rather than preempting it.
  # NVIC priority of device (non-actr) ISRs.
  deviceIrqPriority: NvicPriority = 0
  xpsrThumbOnly = 0x01000000'u32 # xPSR.T set; IPSR, ICI/IT and flags cleared

# The non-volatile Vector Table used at power-on-reset; from vector_table.c
let c_vectorTable {.importc: "c_vectorTable".}: VectorTable

## One shared mutable reference set only by krnl.init()
var k: ptr Krnl

# Forward decls
proc setNvicPriority(irqNmbr: IrqNmbr, nvicPrio: NvicPriority)
proc setPriority(irqNmbr: IrqNmbr, prio: ActrPriority)

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
    frame: ptr StackedFrame, irqNmbr: IrqNmbr, excReturn: uint32
) {.noconv.} =
  ## Dispatches the actr's next event from its queue to its eventHandler
  ## and prepare the stackframe so that when we exit this ISR,
  ## we execute the actr's eventHandler with the proper arguments
  # The frame is only ours to rewrite if this exception returns to Thread mode
  # (EXC_RETURN 0xFFFFFFF9 or 0xFFFFFFE9). Otherwise it belongs to a preempted
  # ISR, which means actr/device IRQ priorities are misconfigured.
  assert (excReturn and 0xF'u32) == 0x9'u32, "dispatchIsr preempted another ISR"
  assert k.actrReg[irqNmbr] != nil, "Actr not registered"
  var actr = k.actrReg[irqNmbr]
  let evnt = actr[].popEvent()
  frame.r0 = cast[uint32](actr)
  frame.r1 = evnt.sig
  frame.r2 = evnt.val
  frame.lr = cast[uint32](proj.lowPowerRunForever)
  frame.pc = cast[uint32](actr[].eventHandler)
  # Don't carry the interrupted code's IT/ICI state into the eventHandler
  frame.xpsr = xpsrThumbOnly

proc dispatchIsr[irqNmbr: static IrqNmbr]() {.noconv, asmNoStackFrame.} =
  ## This isr MUST be placed directly in the vector table
  ## so that SP points at the stacked exception frame on entry
  ## before dispatchIsrBody() rewrites it.
  # irqNmbr is a `static` (compile-time) value, so we must use .emit
  # to splice it in as an immediate ("n" constraint)
  asm "mov r0, sp"
  {.emit: ["asm (\"mov r1, %0\"\n\t:\n\t: \"n\" (", irqNmbr, "));\n"].}
  asm """
    mov r2, lr          // EXC_RETURN, left intact for the exception return
    b `dispatchIsrBody` // tail call — its own epilogue triggers the exception return
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
    NVIC.NVIC_ICPR(0).read().CLRPEND(bitIdx).write()
    NVIC.NVIC_ISER(0).read().SETENA(bitIdx).write()
  of 1:
    NVIC.NVIC_ICPR(1).read().CLRPEND(bitIdx).write()
    NVIC.NVIC_ISER(1).read().SETENA(bitIdx).write()
  else:
    assert irqNmbr < 64, "Fill in more cases"

proc default_Handler() {.importc: "default_Handler", noconv.}

proc registerSignals*(nsHash: NamespaceHash32, maxSig: uint32): SigPubToken =
  ## Register a series of signals with the kernel.
  k.sigReg.registerSignals(nsHash, maxSig)

proc registerIrqHandler*(irqNmbr: IrqNmbr, irqHandler: IrqHandler) =
  ## Sets the device handler in the RAM vector table,
  ## sets its priority and enables the interrupt
  k.vectorTable.setIrqHandler(irqNmbr, irqHandler)
  setNvicPriority(irqNmbr, deviceIrqPriority)
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
  k.vectorTable.setIrqHandler(irqNmbr, dispatchIsr)
  setPriority(irqNmbr, actr[].priority)
  enableIrq(irqNmbr)

proc setNvicPriority(irqNmbr: IrqNmbr, nvicPrio: NvicPriority) =
  ## Sets the NVIC priority of the given external interrupt.
  # NVIC_IPR is byte-accessible, one byte per interrupt, so a single
  # byte store needs no read-modify-write and no critical section.

  when true:
    const nvicIprBase = 0xE000E400'u32
    volatileStore(cast[ptr uint8](nvicIprBase + irqNmbr.uint32), nvicPrio)
  else:
    # TODO: fix metagenerator.nim:106 (non-static index)
    let
      (regIdx, fieldIdx) = divmod(irqNmbr.uint32, 4)
      reg = NVIC.NVIC_IPR(regIdx)

    case fieldIdx
    of 0:
      reg.read().PRI_N0(nvicPrio).write()
    of 1:
      reg.read().PRI_N1(nvicPrio).write()
    of 2:
      reg.read().PRI_N2(nvicPrio).write()
    of 3:
      reg.read().PRI_N3(nvicPrio).write()
    else:
      discard

proc setPriority(irqNmbr: IrqNmbr, prio: ActrPriority) =
  ## Sets the priority of the interrupt associated with an actr
  setNvicPriority(irqNmbr, prio) # implicitly converts ActrPriority
