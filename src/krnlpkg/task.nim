## Copyright 2026 Dean Hall See LICENSE for details
##
## KRNL task operations
##

import cm4f/[core, nvic]
import types

template CRIT_ENTER() =
  disableIrq()

template CRIT_EXIT() =
  enableIrq()

template pend[N, T](self: Task[N, T]) =
  ## Schedules the task for execution by pending its interrupt
  # NOTE: The caller MUST be in a critical section
  let pendReg = case self.irqDiv32
    of 0: NVIC.NVIC_ISPR_0
    of 1: NVIC.NVIC_ISPR_1
    of 2: NVIC.NVIC_ISPR_2
    of 3: NVIC.NVIC_ISPR_3
    else: assert(false) # if assert, declare more registers in arm_cm.nim
  pendReg = self.irqBitf

proc activate*(self: var Task) =
  ## Pops an event within a critical section and calls the task's event handler.
  ## If the task's event queue is not empty after popping,
  ## the task is scheduled for execution again.
  # NOTE: MUST only be called when the task has an event in its queue
  assert self.eventQue.len() > 0'u8
  CRIT_ENTER()
  let e = self.eventQue.pop()
  if self.eventQue.len() > 0:
    self.pend()
  CRIT_EXIT()
  self.dispatch(e)  # task's event handler

func post*[N, T](self: var Task[N, T], e: Evnt[T]) =
  ## Posts an event to the task and schedules the task for execution
  ## within a critical section
  CRIT_ENTER()
  self.eventQue.add(e)
  self.pend()
  CRIT_EXIT()

func setIrq*(self: var Task, irq: uint8) =
  self.nviqIrq = irq
