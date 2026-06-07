## Copyright 2024 Dean Hall See LICENSE for details
##
## KRNL: an event-based microkernel with memory protection for ARM Cortex-M devices
## This takes ideas from Miro Samek's Super-Simple-Tasker and QPc
##   https://github.com/QuantumLeaps/
##
#!fmt: off

import armv7m/[core, fp, nvic, scb]
import nrf52840/device
import debug_rtt, types, task

type
  Handler = proc(self: var Task, e: Evnt)
  LockKey = uint32

const nvicPrioShift = cpu.nvicPriorityBits.uint32

template CRIT_ENTER() =
  disableIrq()

template CRIT_EXIT() =
  enableIrq()

proc init*() =
  discard

func startTask*[N, T](task: var Task[N, T], prio: TaskPriority, initEvnt: Evnt) =
  task.setPriority(prio)
  task.init(initEvnt)

func runForever*(appOnStart: proc) {.noreturn.} =
  if appOnStart != nil:
    appOnStart()
  while true:
    WFI()

####

# I don't have a plan for these two procs yet
#
# proc lock*(ceiling: TaskPriority): LockKey =
#   let nvicPrio: NvicPriority = ceiling
#   result = BASEPRI.read()
#   if result > nvicPrio:
#     CRIT_ENTER()
#     BASEPRI.write(nvicPrio)
#     CRIT_EXIT()
#
# proc unlock*(lockKey: LockKey) =
#   # NOTE: ARMv7-M+ support the BASEPRI register and the selective SST scheduler
#   # unlocking is implemented by restoring BASEPRI to the lockKey level.
#   BASEPRI.write(lockKey)
#
# func newTask*[T](eventQue: ptr RingQue, init: Handler, dispatch: Handler): Task[N, T] =
#   result = Task[N, T]()
#   result.eventQue = eventQue
#   result.init = init
#  result.dispatch = dispatch
