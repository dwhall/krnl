## Copyright 2026 Dean Hall See LICENSE for details
##
## Scheduler for KRNL
##
## KRNL employs the ArmV7M and ArmV8M cores' interrupt controller (NVIC)
## to schedule tasks.  Unused interrupts leave holes in the vector table.
## KRNL fills these holes with a procedure to dispatch an event
## to a specific task's event handler.
## Scheduling a task to run, then, is simply a matter of triggering
## the appropriate interrupt.  This is done either by writing to STIR.INTID
## when only one task is scheduled or by writing to multiple NVIC.NVIC_ISPR[]
## registers when multiple tasks are scheduled.
## The NVIC runs the highest priority pending interrupt and will tail-chain
## to the next highest priority pending interrupt when the first one finishes.
##

import std/math
# TODO: this should be a common import for all ArmV7M and ArmV8M cores:
import cm4f/[nvic, sig]

const PLAT_IRQ_CNT = 256 # placeholder; shold come from device import

type # TODO: this should come from the ARM core import
  InterruptNmbr = uint16

type # TODO: these should come from signal registry
  Bitflags[N: static uint16] = object
    bits: array[N.ceilDiv (8 * sizeof uint32), uint32]

  TaskSet = Bitflags[256]

type # TODO: this should come from the task (common?) import
  Task = object
    irqNmbr: int

type Scheduler = object
  taskRegistry: array[PLAT_IRQ_CNT, ref Task]
  enabled: array[PLAT_IRQ_CNT, bool]

proc registerTask(schd: var Scheduler, task: ref Task) =
  ## Registers a task with this kernel
  schd.taskRegistry[task.irqNmbr] = task
  # TODO: register the task's public emitted signals with the signal registry

proc getTask(schd: Scheduler, irqNmbr: static InterruptNmbr): ref Task =
  ## Returns the task associated with the given irqNmbr.
  schd.taskRegistry[irqNmbr]

proc enable(schd: var Scheduler, task: ref Task) =
  ## Enable a task's interrupt so it can be scheduled
  let (regIdx, bitIdx) = task.irqNmbr.divmod 32
  schd.enabled[task.irqNmbr] = true
  NVIC.NVIC_ISER[regIdx].SETENA[bitIdx](1).write()

proc disable(schd: var Scheduler, task: ref Task) =
  ## Disable the task's interrupt so it won't be scheduled
  let (regIdx, bitIdx) = task.irqNmbr.divmod 32
  schd.enabled[task.irqNmbr] = false
  NVIC.NVIC_ICER[regIdx].SETENA[bitIdx](1).write()

proc schedule(schd: Scheduler, task: ref Task) =
  ## Schedule a single task to run by pending its interrupt
  # FIXME: INTID field has no read access, so rmw won't work
  SIG.STIR.INTID(task.irqNmbr).write()

proc schedule(schd: Scheduler, taskset: TaskSet) =
  ## Schedule multiple tasks to run by pending their interrupts.
  ## In a TaskSet, the bit index corresponds to the task's irqNmbr.
  ## The task set usually comes from the the subscribers to a signal.
  when true:
    when PLAT_IRQ_CNT > 0:
      NVIC.NVIC_ISPR[0] = taskset[0]
    when PLAT_IRQ_CNT > 32:
      NVIC.NVIC_ISPR[1] = taskset[1]
    when PLAT_IRQ_CNT > 64:
      NVIC.NVIC_ISPR[2] = taskset[2]
      NVIC.NVIC_ISPR[3] = taskset[3]
    when PLAT_IRQ_CNT > 128:
      NVIC.NVIC_ISPR[4] = taskset[4]
      NVIC.NVIC_ISPR[5] = taskset[5]
      NVIC.NVIC_ISPR[6] = taskset[6]
      NVIC.NVIC_ISPR[7] = taskset[7]
    # TODO: when PLAT_IRQ_CNT > 256
  else:
    for idx, bundle in taskset.pairs:
      NVIC.NVIC_ISPR[idx] = bundle

proc dispatch(schd: Scheduler, irqNmbr: static InterruptNmbr) =
  ## Dispatches the next event to the task with the given irqNmbr.
  ## WARNING: This procedure is called in the handler context
  const task = schd.getTask(irqNmbr)
  let
    # FIXME: put these in the named registers
    R0 = task.popEvent()
    LR = task.stateHandler
    # TODO: return from interrupt

# Example:
proc dispatchIrq17(schd: Scheduler) =
  ## Declares a dispatch procedure for the task with irqNmbr 17.
  ## This procedure's only use is to be placed in the vector table.
  dispatch(schd, 17)
