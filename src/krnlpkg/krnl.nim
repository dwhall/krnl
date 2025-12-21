#!fmt: off
##
## KRNL: an event-based microkernel with memory protection for ARM Cortex-M devices
## This is a re-write of Miro Samek's Super-Simple-Tasker in the language, Nim
##   https://github.com/QuantumLeaps/Super-Simple-Tasker
##
## Copyright 2024 Dean Hall See LICENSE for details
##
## How-To:
##   main =
##     # your BSP and app init stuff
##     init()
##     start()
##     ...
##     run()
##

import ./arm_cm
import ./ringque

#
# sst.h
#
type
  TaskPrio* = uint8
  Signal* = int32
  Evt*[T] = object
    sig*: Signal
    val*: T
  Task*[N: static uint8, T] = object
    # init*: proc(self: var Task[N, T], e: Evt[T])
    # dispatch*: proc(self: var Task[N, T], e: Evt[T])
    eventQue: RingQue[N, T]
    # ARM Cortex-M specific task attributes:
    nvicPendRegIdx: uint32
    nvicIrq: uint32

type
  Handler = proc(self: var Task, e: Evt)

  LockKey* = uint32

#
# sst_port.h
#
func CRIT_ENTRY*() {.inline.} =
  asm "cpsid i"

func CRIT_EXIT*() {.inline.} =
  asm "cpsie i"

func pend*[N, T](task: Task[N, T]) {.inline.} =
  ## Pend the Task after posting an event
  ## NOTE: executed inside SST critical section.
  let setPendingReg = case task.nvicPendRegIdx
    of 0: NVIC.ISPR0
    of 1: NVIC.ISPR1
    of 2: NVIC.ISPR2
    of 3: NVIC.ISPR3
    else: assert(false) # if assert, declare more ISPRx registers in arm_cm.nim
  setPendingReg.SETPEND = task.nvicIrq

#
# sst_port.c
#

# TBD: make this const (based on nvicPrioBits) and assert if it differs in init()
const nvicPrioShift: uint32 = nvicPrioBits.uint32

proc init* =
  # Determine the number of NVIC priority bits by writing 0xFF to the
  # NVIC IP register for PendSV and then reading back the result,
  # which has only the implemented bits set.
  let tmp = SCB.SHPR3   # store original value
  SCB.SHPR3
     .PRI_14(0xFF)      # write to PendSV prio
     .write()
  let prio = SCB.SHPR3.PRI_14.int # read back
  SCB.SHPR3 = tmp       # restore original value

  var n: uint32
  for n in 0 ..< 8:
    if (prio and (1 shl n)) != 0:
      break
  assert nvicPrioShift == n, "Calculated priority shift does not match declaration.  Does the compiler have the right MCU?"

  when fpuPresent:    # Configure the FPU
    SCB.FPCCR
      .ASPEN(1)       # enable automatic FPU state preservation
      .LSPEN(1)       # enable lazy stacking
      .write()

proc start =
  ## Set the NVIC priority grouping to 0 (default)
  # NOTE: Typically the SST port to ARM Cortex-M should waste no NVIC priority
  # bits for grouping. This code ensures this setting, but priority
  # grouping can be still overridden by the application
  # after this procedure is called and before run() is called.
  # (SST calls this the onStart() callback)
  const writeKey = 0x05FA
  SCB.AIRCR
     .PRIGROUP(0)
     .VECTKEY(writeKey)
     .write()


proc setPrio(self: var Task, prio: TaskPrio) =
  assert self.nvicIrq > 0                   # DBC_REQUIRE(200
  assert prio <= (0xFF'u shr nvicPrioShift) # DBC_REQUIRE(201

  # Convert the Task priority (1,2,..) to NVIC priority...
  let nvic_prio = ((0xFF'u shr nvicPrioShift) + 1'u - prio) shl nvicPrioShift
  assert((self.nvicIrq shr 2) <= 1) # if asserts, declare more registers in arm_cm.nim and use them here (maybe make an array)
  let prioReg = case(self.nvicIrq shr 2)
    of 0: NVIC.IPR0
    else: NVIC.IPR1
  let prioRegField = case(self.nvicIrq and 0b11)
    of 0: prioReg.PRI_N0
    of 1: prioReg.PRI_N1
    of 2: prioReg.PRI_N2
    of 3: prioReg.PRI_N3

  assert((self.nvicIrq shr 5) <= 3) # if asserts, declare more registers in arm_cm.nim and use them here (maybe make an array)
  let irqReg = case (self.nvicIrq shr 5)
    of 0: NVIC.ISER0
    of 1: NVIC.ISER1
    of 2: NVIC.ISER2
    else: NVIC.ISER3
  let irqBit = 1 shl (self.nvicIrq and 0x1F)

  CRIT_ENTRY()

  # Set the Task priority of the associated IRQ
  prioRegField = nvic_prio

  # Enable the IRQ associated with the Task
  irqReg.SETENA = irqReg.SETENA.uint32 or irqBit

  CRIT_EXIT()

  # Store the NVIC Set-Pending register and the IRQ bit
  self.nvicPendRegIdx = (self.nvicIrq shr 5)
  self.nvicIrq = irqBit

proc activate*(self: var Task) =
  assert self.nUsed > 0'u8  # DBC_REQUIRE(300

  CRIT_ENTRY()
  # Get the event out of the queue
  let e = self.eventQue.pop()
  if self.eventQue.len() > 0:
    # select the set-pending register
    let pendReg = case self.nvicPendRegIdx
      of 0: NVIC.ISPR0
      of 1: NVIC.ISPR1
      of 2: NVIC.ISPR2
      of 3: NVIC.ISPR3
      else: assert(false) # if assert, declare more registers in arm_cm.nim
    # pend the associated IRQ
    pendReg.SETPEND = self.nvicIrq

  CRIT_EXIT()

  # dispatch the received event to this task
  self.dispatch(self, e)


func setIRQ*(self: var Task, irq: uint8) =
  self.nvicIrq = irq


proc lock*(ceiling: TaskPrio): LockKey =
  let nvicPrio: uint8 = ((0xFF'u8 shr nvicPrioShift) + 1'u8 - ceiling.uint8) shl nvicPrioShift
  {.emit: ["asm (\"mrs %0, BASEPRI\"\n\t: \"=r\" (", result, ")\n\t:: );\n"].}
  if result > nvicPrio:
    {.emit: ["cpsid i\n\tmsr BASEPRI, %0\n\tcpsie i\n\t:: \"r\" (", nvicPrio, ") :\n"].}


proc unlock*(lockKey: LockKey) =
  # NOTE: ARMv7-M+ support the BASEPRI register and the selective SST scheduler
  # unlocking is implemented by restoring BASEPRI to the lockKey level.
  {.emit: ["msr BASEPRI, %0\n\t:: \"r\" (", lockKey, ")\n\t:\n"].}


#
# sst.c
#

func run*(appOnStart: proc) {.noreturn.} =
  start()
  appOnStart()
  while true:
    asm "__wfi"

# func newTask*[T](eventQue: ptr RingQue, init: Handler, dispatch: Handler): Task[N, T] =
#   result = Task[N, T]()
#   result.eventQue = eventQue
#   result.init = init
#  result.dispatch = dispatch

func start*[N, T](self: var Task[N, T], prio: TaskPrio, initEvt: Evt) =
  # DBC_REQUIRE(200 prio > 0) ...
  self.setPrio(prio)
  self.init(initEvt)

func post*[N, T](self: var Task[N, T], e: Evt[T]) =
  # DBC_REQUIRE(300, self.nUsed <= self.end)
  CRIT_ENTRY()
  self.eventQue.add(e)
  self.pend()
  CRIT_EXIT()


#
# Kernel timer event and methods
#

type
  TCtr = uint16

  TimeEvt*[N: static uint8, T] = ref object
    super: Evt[T]
    next: TimeEvt[N, T]
    task: Task[N, T]
    ctr: TCtr
    interval: TCtr

proc newTimeEvt*[N, T](head: TimeEvt[N, T], sig: Signal, task: Task[N, T]): TimeEvt[N, T] =
  # f.k.a. ctor
  ## Inserts a new TimeEvt at the head of the linked list
  # implicit allocation of TimeEvt node in variable, result
  result.sig = sig
  result.task = task
  result.next = head
  head = result

func arm*[N, T](self: var TimeEvt[N, T], ctr: TCtr, interval: TCtr = 0) =
  ## Arms the TimeEvt with the given counter value
  ## The interval argument defaults to zero, which arms a one-shot timer.
  ## Set interval to non-zero for a repeating timer.
  CRIT_ENTRY()
  self.ctr = ctr
  self.interval = interval
  CRIT_EXIT()

func disarm*[N, T](self: var TimeEvt[N, T]): bool =
  ## Disarms the given timer.  The timer remains in the list.
  CRIT_ENTRY()
  result = (self.ctr != 0)
  self.ctr = 0
  self.interval = 0
  CRIT_EXIT()

# usually called by the SysTick ISR handler
proc tick*[N, T](head: ref TimeEvt[N, T]) =
  ## For each timer event in the list:
  ##    If the counter is 0, do nothing.  The counter is expired.
  ##    If the counter is 1, dispatches the event to its task
  ##    and resets the counter with the interval value.
  ##    Otherwise, decrements the counter by one.
  var t = head
  while t != nil:
    CRIT_ENTRY()
    if t.ctr == 0:
      CRIT_EXIT()
    elif t.ctr == 1:
      t.ctr = t.interval
      CRIT_EXIT()
      t.task.post(t.super)
    else:
      dec t.ctr
      CRIT_EXIT()
    t = t.next
