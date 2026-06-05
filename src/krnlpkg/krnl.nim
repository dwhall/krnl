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

proc init* =
  ## Validates the NVIC's priority configuration
  ## and configures the core's floating-point unit

  # Determine the number of NVIC priority bits by writing all ones to the
  # NVIC IP register for PendSV and then reading back the result,
  # which has only the implemented bits set.
  let tmp = SCB.SHPR3.read() # store original value
  SCB.SHPR3.read()
           .PRI_14(0xFF) # write to PendSV prio
           .write()
  let prio = SCB.SHPR3.read().PRI_14.uint8 # read back implemented prio bits
  SCB.SHPR3.write(tmp) # restore original value
  # prio is an 8-bit field with the implemented bits set and packed toward the MSb.
  # nvicPrioShift is the offset to the least significant set bit of prio.
  let n = firstSetBit(prio) - 1
  # If you reach this assert, either you used the wrong SVD file for your MCU
  # or the cpu/nvicPrioBits value in your SVD file is incorrect
  assert nvicPrioShift == n, "Calculated priority shift does not match declaration from SVD."

  when cpu.fpuPresent:  # Configure the floating-point unit
    FP.FPCCR.read()
            .ASPEN(1) # enable automatic FPU state preservation
            .LSPEN(1) # enable lazy stacking
            .write()

func startTask*[N, T](task: var Task[N, T], prio: TaskPriority, initEvnt: Evnt) =
  task.setPriority(prio)
  task.init(initEvnt)

func runForever*(appOnStart: proc) {.noreturn.} =
  const writeKey = 0x05FA
  SCB.AIRCR.read()
           .VECTKEY(writeKey)
           .PRIGROUP(0) # clear NVIC priority grouping
           .write()

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
