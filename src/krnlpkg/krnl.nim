# KRNL: an event-based microkernel with memory protection for ARM Cortex-M devices
#
# Copyright 2024 Dean Hall See LICENSE for details
#

const buildTarget {.strdefine: "target".}: string = "arm_cm"


type
  Signal* = int32
  TaskPrio* = int8
  Qctr = uint8

  Evt*[T] = object of RootObj
    sig*: Signal
    val*: T

  Handler[T] = proc(self: Task[T], e: Evt[T])

  Task*[T] = object of RootObj
    init: Handler[T]
    dispatch: Handler[T]
    qBuf: ref openArray[T] = nil
    term: Qctr # f.k.a. "end", a keyword in nim
    head: Qctr
    tail: Qctr
    nUsed: Qctr

# Target-specific declarations
func TASK_PEND[T](self: var Task[T])
func CRIT_ENTRY()
func CRIT_EXIT()

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
  CRIT_ENTRY()
  self.qBuf[self.head] = e
  if self.head == 0:
    self.head = self.term
  else:
    dec self.head
  TASK_PEND(self)
  CRIT_EXIT()
