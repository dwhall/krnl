## Copyright 2026 Dean Hall See LICENSE for details
##
## KRNL task operations
##

import cm4f/[core, sig]
import types

template CRIT_ENTER() =
  disableIrq()

template CRIT_EXIT() =
  enableIrq()

template schedule[N, T](self: Task[N, T]) =
  ## Schedules the task for execution by pending its interrupt in the NVIC
  # NOTE: The caller MUST be in a critical section in privileged mode
  SIG.STIR
     .INTID(self.irqNum)
     .write()

proc activate*(self: var Task) =
  ## Pops an event within a critical section and calls the task's event handler.
  ## If the task's event queue is not empty after popping,
  ## the task is scheduled for execution again.
  # NOTE: MUST only be called when the task has an event in its queue
  # NOTE: The caller MUST be in privileged mode
  assert self.eventQue.len() > 0'u8
  CRIT_ENTER()
  let e = self.eventQue.pop()
  if self.eventQue.len() > 0:
    self.schedule()
  CRIT_EXIT()
  self.dispatch(e)  # task's event handler

func post*[N, T](self: var Task[N, T], e: Evnt[T]) =
  ## Posts an event to the task and schedules the task for execution
  ## within a critical section
  # NOTE: The caller MUST be in privileged mode
  CRIT_ENTER()
  self.eventQue.add(e)
  self.schedule()
  CRIT_EXIT()

func setIrq*(self: var Task, irq: uint8) =
  self.irqNum = irq
