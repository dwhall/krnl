## Copyright 2024 Dean Hall See LICENSE for details
##
## KRNL
##

import std/[math, volatile]
import armv7m/[core, nvic, scb]
import plat, proj, vectortable
import ./[actr, actr_set, effects, event, namespace, signal, signal_registry]

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
  ## to NvicPriority where 0 is the highest priority.
  ## The NVIC implements only the most significant nvicPriorityBits of each
  ## priority byte, so the level is shifted up into those bits.
  ## ActrPriority's range keeps every actr less urgent than NVIC level 0,
  ## which is reserved for device ISRs (deviceIrqPriority).
  const
    unusedBits = 8 - plat.nvicPriorityBits()
    lowestLevel = (1'u32 shl plat.nvicPriorityBits()) - 1'u32
  NvicPriority((lowestLevel - prio.uint32) shl unusedBits)

const
  # Actr interrupt priorities must never be more urgent than a dev
  # so that an actr's dispatchIsr always tail-chains after a device ISR
  # (which may post() to it) rather than preempting it.
  # NVIC priority of device (non-actr) ISRs.
  deviceIrqPriority: NvicPriority = 0

# The non-volatile Vector Table used at power-on-reset; from vector_table.c
let c_vectorTable {.importc: "c_vectorTable".}: VectorTable

## One shared mutable reference set only by krnl.init()
var k: ptr Krnl

# Forward decls
proc setNvicPriority(
  irqNmbr: IrqNmbr, nvicPrio: NvicPriority
) {.tags: [PrivilegedModeEffect].}

proc setPriority(irqNmbr: IrqNmbr, prio: ActrPriority) {.tags: [PrivilegedModeEffect].}

proc initKrnl*(self: ptr Krnl) =
  ## Saves a reference to the Krnl and COPIES the non-vol vector table to RAM
  ## This is called before switchToRamVectorTable()
  k = self # this should be the ONLY place where k is set
  k.vectorTable = c_vectorTable
  # A dispatchIsr that preempts another dispatchIsr enters Thread mode
  # while that one is still active (see Actr dispatch)
  SCB.CCR.read().NONBASETHRDENA(1).write()

proc switchToRamVectorTable*() {.tags: [PrivilegedModeEffect].} =
  SCB.VTOR.write(cast[uint32](addr k.vectorTable))

proc exitPrivilegedMode*() {.tags: [PrivilegedModeEffect].} =
  CONTROL.nPRIV(1)
  ISB()

## Actr dispatch
##
## Each dispatch pushes a fresh DispatchFrame below whatever the dispatchIsr
## interrupted, so eventHandlers nest on the single stack by NVIC priority:
##
##   [interrupted context's exception frame]  <- SP on dispatchIsr entry
##   DispatchFrame.excReturn
##   DispatchFrame.savedBasepri                <- SP while the eventHandler runs
##   DispatchFrame.frame (r0..xpsr)            <- SP at dispatchIsr's exception return
##
## dispatchIsr's exception return pops `frame`, entering the eventHandler in
## Thread mode with BASEPRI masking actrs of equal or lower priority.
## The eventHandler returns into dispatchReturn, whose SVC lands in
## dispatchReturnSvc, which restores BASEPRI and resumes the interrupted context.
## Pending actrs that BASEPRI was masking then tail-chain into their dispatchIsr.
##
## A dispatchIsr may preempt a less urgent actr's dispatchIsr (e.g. a device ISR
## publishes to it while the other dispatchIsr runs).  It then enters its
## eventHandler in Thread mode while that dispatchIsr is still active,
## which requires CCR.NONBASETHRDENA (set in initKrnl).

type DispatchFrame = object
  frame: StackedFrame # popped by dispatchIsr's exception return
  savedBasepri: uint32 # BASEPRI of the interrupted context
  excReturn: uint32 # EXC_RETURN that resumes the interrupted context

# dispatchIsr's and dispatchReturnSvc's asm depend on this layout
static:
  assert sizeof(DispatchFrame) == 40
  assert offsetOf(DispatchFrame, savedBasepri) == 32
  assert offsetOf(DispatchFrame, excReturn) == 36

proc dispatchReturn() {.noconv, asmNoStackFrame, noreturn.} =
  ## Every eventHandler returns here (Thread mode, possibly unprivileged)
  ## with SP pointing at its DispatchFrame.savedBasepri.
  ## SVC #1 is handled by dispatchReturnSvc.
  asm "svc #1"

proc dispatchReturnSvc*() {.noconv, asmNoStackFrame, tags: [PrivilegedModeEffect].} =
  ## SVC_Handler branches here for SVC #1 with R0 = the SVC's stacked frame
  ## and LR = the SVC's EXC_RETURN.  Discards the SVC's frame, restores the
  ## BASEPRI saved by dispatchIsrBody and resumes the context that the
  ## dispatchIsr interrupted.  Assumes the single stack (MSP).
  asm """
    tst   lr, #0x10       // EXC_RETURN bit 4: 0 = the SVC's frame holds FP state
    ite   eq
    addeq r1, r0, #0x68   // r1 = address just past the SVC's frame
    addne r1, r0, #0x20
    ldr   r2, [r0, #28]   // stacked xPSR bit 9: frame was padded for alignment
    tst   r2, #0x200
    it    ne
    addne r1, r1, #4      // r1 = ptr to DispatchFrame.savedBasepri
  """
  when plat.fpuAvail():
    # The eventHandler used the FPU, so the SVC's entry left a lazy FP save
    # pending into the frame we are discarding.  Clear FPCCR.LSPACT to abandon it,
    # so returning to an FP frame restores the interrupted context's FP state.
    asm """
    tst   lr, #0x10
    itttt eq
    movweq r2, #0xEF34    // FPCCR = 0xE000EF34
    movteq r2, #0xE000
    ldreq r3, [r2]
    biceq r3, r3, #1      // LSPACT
    it    eq
    streq r3, [r2]
    """
  asm """
    ldr   r2, [r1, #0]    // DispatchFrame.savedBasepri
    ldr   lr, [r1, #4]    // DispatchFrame.excReturn
    add   r1, r1, #8      // r1 = interrupted context's exception frame
    msr   msp, r1
    msr   basepri, r2     // unmasks pending actrs, which tail-chain after bx
    bx    lr
  """

proc dispatchIsrBody(ctx: ptr DispatchFrame, irqNmbr: IrqNmbr) {.noconv.} =
  ## Pops the actr's next event from its queue and fills in ctx so that
  ## dispatchIsr's exception return calls the actr's eventHandler
  ## with the event and then returns into dispatchReturn.
  const xpsrThumbOnly = 0x01000000'u32 # xPSR.T set; IPSR, IT/ICI and flags cleared
  # Actrs are less urgent than every other exception, so a dispatchIsr only
  # interrupts Thread mode or another (less urgent) dispatchIsr, both on MSP.
  assert (ctx.excReturn and 0x4'u32) == 0, "dispatchIsr interrupted a PSP context"
  assert k.actrReg[irqNmbr] != nil, "Actr not registered"
  let actr = k.actrReg[irqNmbr]
  let evnt = actr[].popEvent()
  ctx.frame.r0 = cast[uint32](actr)
  ctx.frame.r1 = evnt.sig
  ctx.frame.r2 = evnt.val
  ctx.frame.r3 = 0
  ctx.frame.r12 = 0
  ctx.frame.lr = cast[uint32](dispatchReturn)
  ctx.frame.pc = cast[uint32](actr[].eventHandler) and not 1'u32
  ctx.frame.xpsr = xpsrThumbOnly
  # Run-to-completion: mask this actr and all less urgent actrs while
  # its eventHandler runs; more urgent actrs may still preempt (nest).
  ctx.savedBasepri = BASEPRI.read().uint32
  BASEPRI.PRI(actr[].priority.toNvicPriority.uint32)

proc dispatchIsr[irqNmbr: static IrqNmbr]() {.noconv, asmNoStackFrame.} =
  ## This isr MUST be placed directly in the vector table
  ## so that SP points at the interrupted context's exception frame on entry.
  ## It reserves a DispatchFrame below that frame, has dispatchIsrBody fill it,
  ## then exception-returns through it into the actr's eventHandler.
  asm """
    sub   sp, sp, #40     // reserve a DispatchFrame (keeps 8-byte alignment)
    str   lr, [sp, #36]   // DispatchFrame.excReturn
    mov   r0, sp          // r0 = ptr to DispatchFrame
  """
  # irqNmbr is a `static` (compile-time) value, so we must use .emit
  # to splice it in as an immediate ("n" constraint)
  {.emit: ["asm (\"mov r1, %0\"\n\t:\n\t: \"n\" (", irqNmbr, "));\n"].}
  asm """
    bl    `dispatchIsrBody`
    mvn   lr, #6          // EXC_RETURN 0xFFFFFFF9: Thread mode, MSP, basic frame
    bx    lr              // pops DispatchFrame.frame into the eventHandler
  """

# TODO:
# macro genDispatchIsrArray(): untyped =
#   ## Static array mapping each IrqNmbr(N) to its dispatchIsr[N] proc.
#   ## Builds `[dispatchIsr[0], dispatchIsr[1], ..., dispatchIsr[high(IrqNmbr)]]`,
#   ## which instantiates dispatchIsr[N] for every valid IrqNmbr.
#   result = newTree(nnkBracket)
#   for n in low(IrqNmbr).int .. high(IrqNmbr).int:
#     result.add newTree(nnkBracketExpr, ident"dispatchIsr", newLit(uint8 n))
#
# const dispatchIsrArray: array[IrqNmbr, proc()] = [
const dispatchIsrArray =
  [dispatchIsr[0], dispatchIsr[1], dispatchIsr[2], dispatchIsr[3]]

proc enableIrq(irqNmbr: IrqNmbr) {.tags: [PrivilegedModeEffect].} =
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
  actr[].irqNmbr = irqNmbr
  k.actrReg[irqNmbr] = actr
  let dispatchIsr = dispatchIsrArray[irqNmbr.int]
  k.vectorTable.setIrqHandler(irqNmbr, dispatchIsr)
  setPriority(irqNmbr, actr[].priority)
  enableIrq(irqNmbr)

proc setNvicPriority(
    irqNmbr: IrqNmbr, nvicPrio: NvicPriority
) {.tags: [PrivilegedModeEffect].} =
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

proc subscribe*(actr: ptr Actr, sig: Signal) =
  ## Subscribes an already-registered actr to a published signal.
  assert actr != nil and actr in k.actrReg
  k.sigReg.subscribe(sig, actr[].irqNmbr)

proc unsubscribe*(actr: ptr Actr, sig: Signal) =
  ## Unsubscribes an actr from a signal.
  assert actr != nil and actr in k.actrReg
  k.sigReg.unsubscribe(sig, actr[].irqNmbr)

proc publishEvent*(evnt: Event) =
  ## Copies `evnt` to every actr subscribed to the event's signal and schedules
  ## them.  Callable from a kernel interrupt handler or privileged thread.
  # TBD: crit section?
  let subscribers = k.sigReg.getSubscribersTo(evnt.sig)
  for (n, actr) in k.actrReg.pairs:
    if (actr != nil) and subscribers.contains(IrqNmbr(n)):
      actr[].postEvent(evnt)
  subscribers.schedule()
