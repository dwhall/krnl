# KRNL: an event-based microkernel with memory protection for ARM Cortex-M devices
#
# Copyright 2024 Dean Hall See LICENSE for details
#

include port


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
    when buildTarget == "arm_cm":
      nvic_pend: uint32
      nvic_irq: uint32

func ctor[T](self: var Task[T], init: Handler[T], dispatch: Handler[T]) =
  self.init = init
  self.dispatch = dispatch

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

proc newTimeEvt[T](head: ref TimeEvt, sig: Signal, task: Task[T]): TimeEvt[T] =  # f.k.a. ctor
  result.sig = sig
  result.task = task
  # insert self into linked list
  result.next = head
  head = ref result

func arm[T](self: var TimeEvt[T], ctr: TCtr, interval: Tctr = 0) =
  CRIT_STAT
  CRIT_ENTRY()
  self.ctr = ctr
  self.interval = interval
  CRIT_EXIT()

func disarm[T](self: var TimeEvt[T]): bool =
  CRIT_STAT
  CRIT_ENTRY()
  result = (self.ctr != 0)
  self.ctr = 0
  self.interval = 0
  CRIT_EXIT()

proc tick[T](head: ref TimeEvt) =
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
