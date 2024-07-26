# KRNL: an event-based microkernel with memory protection for ARM Cortex-M devices
#
# Copyright 2024 Dean Hall See LICENSE for details
#

import std/bitops


type
  Signal* = int32
  TaskPrio* = int8
  Qctr = uint8

  Evt*[T] = object
    sig*: Signal
    val*: T

  Handler[T] = proc(self: Task[T], e: Evt[T])

  Task*[T] = object
    init: Handler[T]
    dispatch: Handler[T]
    qBuf: ref openArray[T] = nil
    term: Qctr # f.k.a. "end", a keyword in nim
    head: Qctr
    tail: Qctr
    nUsed: Qctr
    nvic_pend: uint32
    nvic_irq: uint32

var nvicPrioShift: uint8  # FIXME: should use TaskPrio type

func ctor[T](self: var Task[T], init: Handler[T], dispatch: Handler[T]) =
  self.init = init
  self.dispatch = dispatch

template TASK_PEND(self: typed): untyped =
  self.nvic_pend = self.nvic_irq

func CRIT_ENTRY {.inline.} =
  asm "cpsid i"

func CRIT_EXIT {.inline.} =
  asm "cpsie i"

func runForever {.noreturn.} =
  while true:
      asm "__wfi"

func CRIT_STAT {.inline.} =
  discard

func start[T](self: var Task[T], prio: TaskPrio, qBuf: openArray[T], qLen: QCtr, ie: Evt[T]) =
  # DBC_REQUIRE(200 prio > 0) ...
  self.qBuf = qBuf
  self.term = qLen - 1
  self.head = 0
  self.tail = 0
  self.nUsed = 0
  self.setPrio(prio)
  # dispatch the initialization event
  self.init(ie)

func post[T](self: var Task[T], e: Evt[T]) =
  # DBC_REQUIRE(300, self.nUsed <= self.end)
  CRIT_STAT
  CRIT_ENTRY()
  self.qBuf[self.head] = e
  if self.head == 0:
    self.head = self.term
  else:
    dec self.head
  inc self.nUsed
  TASK_PEND(self)
  CRIT_EXIT()

proc init =
  # Determine the number of NVIC priority bits by writing 0xFF to
  # the NIVIC IP register for PendSV and then reading back the
  # result, which has only the implemented bits set.
  # FIXME:
  # let tmp = SCB.SYSPRI[3]
  # SCB.SYSPRI[3] = bitor(SCB.SYSPRI[3], (0xFFu shl 16'u))
  # let prio = bitand((SCB.SYSPRI[3] shr 16'u), 0xFF'u)
  # SCB.SYSPRI[3] = tmp
  var tmp = 0'u8  # REMOVE
  var prio = 0'u

  for tmp in 0'u..8'u:
    if bitand(prio, (1'u shl tmp)) != 0:
      break
  nvicPrioShift = tmp
  # TODO: compare against the value we get from the SVD file

  when defined(ARM_FP):
    # Enable the FPU's automatic state preservation and lazy stacking
    FPU.FPCCR = bitor(FPU.FPCCR, (1'u shl 30), (1'u shl 31))

proc start =
  # Set the NVIC priority grouping to default 0
  # FIXME:
  # var tmp = SCB.AIRCR
  # tmp = tmp bitand bitnot(bitor((0xFFFF'u shl 16), (0x07'u shl 8)))
  # SCB.AIRCR = bitor((0x05FA'u shl 16), tmp)
  discard

proc setPrio(self: var Task, prio: TaskPrio) =
  # DBC_REQUIRE(200, self.nvic_irq != 0)
  # DBC_REQUIRE(201, prio <= (0xff'u shr nvic_prio_shift))

  # Convert the SST direct priority (1,2,..) to NVIC priority...
  let nvic_prio = ((0xFF'u shr nvic_prio_shift) + 1'u - prio) shl nvic_prio_shift

  CRIT_STAT
  CRIT_ENTRY()

  # Set the Task priority of the associated IRQ
  var tmp = NVIC_IP[self.nvic_irq shr 2]
  tmp = bitand(tmp, bitnot(0xFF'u shl (bitand(self.nvic_irq, 3) shl 3)))
  tmp = bitor(tmp, nvic_prio shl (bitand(self.nvic_irq, 3) shl 3))
  NVIC_IP[self.nvic_irq shr 2] = tmp

  # Enable the IRQ associated with the Task
  NVIC_EN[self.nvic_irq shr 5] = (1'u32 shl bitand(self.nvic_irq, 0x1F))
  CRIT_EXIT()

  # Store the address of NVIC_PEND address and the IRQ bit
  self.nvic_pend = NVIC_PEND[self.nvic_irq shr 5]   # FIXME? was: &NVIC_PEND
  self.nvic_irq = (1'u32 shl bitand(self.nvic_irq, 0x1F))

#
# Kernel timer event and methods
#

type
  Tctr = uint16

  TimeEvt*[T] = object
    super: Evt[T]
    next: ref TimeEvt[T]
    task: ref Task[T]
    ctr: Tctr
    interval: Tctr
  TimeEvtRef[T] = ref TimeEvt[T]

proc newTimeEvt[T](head: TimeEvtRef[T], sig: Signal, task: Task[T]): TimeEvtRef[T] =  # f.k.a. ctor
  ## Inserts a new TimeEvt at the head of the linked list
  # implicit allocation of TimeEvt node in variable, result
  result.sig = sig
  result.task = task
  result.next = head
  head = result

func arm[T](self: var TimeEvt[T], ctr: TCtr, interval: Tctr = 0) =
  ## Arms the TimeEvt with the given counter value
  ## The interval argument defaults to zero, which arms a one-shot timer.
  ## Set interval to non-zero for a repeating timer.
  CRIT_STAT
  CRIT_ENTRY()
  self.ctr = ctr
  self.interval = interval
  CRIT_EXIT()

func disarm[T](self: var TimeEvt[T]): bool =
  ## Disarms the given timer.  The timer remains in the list.
  CRIT_STAT
  CRIT_ENTRY()
  result = (self.ctr != 0)
  self.ctr = 0
  self.interval = 0
  CRIT_EXIT()

proc tick[T](head: ref TimeEvt) =
  ## For each timer event in the list:
  ##    If the counter is 0, do nothing.  The counter is expired.
  ##    If the counter is 1, dispatches the event to its task
  ##    and resets the counter with the interval value.
  ##    Otherwise, decrements the counter by one.
  var t = head
  while t != nil:
    CRIT_STAT
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
