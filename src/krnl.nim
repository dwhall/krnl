# KRNL: an event-based microkernel with memory protection for ARM Cortex-M devices
#
# Copyright 2024 Dean Hall See LICENSE for details
#

const buildTarget {.strdefine: "target".}: string = "arm_cm"


type
  Signal = int32
  TaskPrio = int8
  Qctr = uint8

  Evt[T] = object of RootObj
    sig: Signal
    val: T

  Task[T] = object of RootObj
    init: proc(self: Task[T], e: Evt[T])
    dispatch: proc(self: Task[T], e: Evt[T])
    qBuf: ref openArray[T]
    term: Qctr # f.k.a. "end", a keyword in nim
    head: Qctr
    tail: Qctr
    nUsed: Qctr
    when buildTarget == "arm_cm":
      nvic_pend: uint32
      nvic_irq: uint32

  Handler[T] = proc(self: Task[T], e: Evt[T])


func ctor[T](self: var Task[T], init: Handler[T], dispatch: Handler[T]) =
  self.init = init
  self.dispatch = dispatch

func TASK_PEND[T](self: var Task[T]) {.inline.} =
  when buildTarget == "arm_cm":
    self.nvic_pend = self.nvic_irq

func CRIT_ENTRY {.inline.} =
  when buildTarget == "arm_cm":
    asm "cpsid i"

func CRIT_EXIT {.inline.} =
  when buildTarget == "arm_cm":
    asm "cpsie i"

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
  CRIT_ENTRY()
  self.qBuf[self.head] = e
  if self.head == 0:
    self.head = self.term
  else:
    dec self.head
  TASK_PEND(self)
  CRIT_EXIT()

func runForever {.noreturn.} =
  while true:
    when buildTarget == "arm_cm":
      asm "__wfi"
