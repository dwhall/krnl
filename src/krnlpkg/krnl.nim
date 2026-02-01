#!fmt: off
## Copyright 2024 Dean Hall See LICENSE for details
##
## KRNL: an event-based microkernel with memory protection for ARM Cortex-M devices
## This takes ideas from Miro Samek's Super-Simple-Tasker and QPc
##   https://github.com/QuantumLeaps/
##

import std/[bitops, math]
import cm4f/[core, fp, nvic, scb]
import nrf52840/device
import ringque, types

type
  Handler = proc(self: var Task, e: Evnt)
  LockKey = uint32

const nvicPrioShift = cpu.nvicPrioBits.uint32

template CRIT_ENTER() =
  disableIrq()

template CRIT_EXIT() =
  enableIrq()

converter toNvicPrio(prio: TaskPrio): NvicPrio =
  ## Converts TaskPrio where 0 is the lowest priority
  ## to NvicPrio where 0 is the highest priority
  ((0xFF'u32 shr nvicPrioShift) + 1'u32 - prio) shl nvicPrioShift

# Forward declarations
proc setPrio(self: var Task, prio: TaskPrio)

proc init* =
  ## Validates the NVIC's priority configuration
  ## and configures the core's floating-point unit

  # Determine the number of NVIC priority bits by writing all ones to the
  # NVIC IP register for PendSV and then reading back the result,
  # which has only the implemented bits set.
  let tmp = SCB.SHPR3   # store original value
  SCB.SHPR3
     .PRI_14(0xFF)      # write to PendSV prio
     .write()
  let prio = SCB.SHPR3.PRI_14.uint8 # read back implemented prio bits
  SCB.SHPR3 = tmp       # restore original value
  # prio is an 8-bit field with the implemented bits set and packed toward the MSb.
  # nvicPrioShift is the offset to the least significant set bit of prio.
  let n = firstSetBit(prio) - 1
  # If you reach this assert, either you used the wrong SVD file for your MCU
  # or the cpu/nvicPrioBits value in your SVD file is incorrect
  assert nvicPrioShift == n, "Calculated priority shift does not match declaration from SVD."

  when cpu.fpuPresent:  # Configure the floating-point unit
    FP.FPCCR
      .ASPEN(1) # enable automatic FPU state preservation
      .LSPEN(1) # enable lazy stacking
      .write()

func startTask*[N, T](self: var Task[N, T], prio: TaskPrio, initEvnt: Evnt) =
  # TODO: init priority queue?
  self.setPrio(prio)
  self.init(initEvnt)

proc setPrio(self: var Task, prio: TaskPrio) =
  ## Sets the this task's interrupt's priority
  ## and enables the interrupt in the NVIC
  assert self.nviqIrq > 0'u8
  assert prio <= (0xFF'u8 shr nvicPrioShift)

  let (irqDiv4, irqMod4) = divmod(self.nviqIrq, 4'u8)
  let prioReg = case irqDiv4
    of 0: NVIC.NVIC_IPR_0
    of 1: NVIC.NVIC_IPR_1
    of 2: NVIC.NVIC_IPR_2
    of 3: NVIC.NVIC_IPR_3
    of 4: NVIC.NVIC_IPR_4
    of 5: NVIC.NVIC_IPR_5
    of 6: NVIC.NVIC_IPR_6
    of 7: NVIC.NVIC_IPR_7
    of 8: NVIC.NVIC_IPR_8
    of 9: NVIC.NVIC_IPR_9
    of 10: NVIC.NVIC_IPR_10
    of 11: NVIC.NVIC_IPR_11
    of 12: NVIC.NVIC_IPR_12
    of 13: NVIC.NVIC_IPR_13
    of 14: NVIC.NVIC_IPR_14
    of 15: NVIC.NVIC_IPR_15
    # This will only assert when the MCU has more than 128 interrupts.
    # If this asserts, expand the case-of table
    else: assert(false)

  let (irqDiv32, irqMod32) = divmod(self.nviqIrq, 32'u8)
  let irqBitf = 1'u32 shl irqMod32
  let iserReg = case irqDiv32
    of 0: NVIC.NVIC_ISER_0
    of 1: NVIC.NVIC_ISER_1
    of 2: NVIC.NVIC_ISER_2
    of 3: NVIC.NVIC_ISER_3
    # This will only assert when the MCU has more than 128 interrupts.
    # If this asserts, expand the case-of table
    else: assert(false)

  let nvicPrio: NvicPrio = prio # implicitly calls the converter
  CRIT_ENTER()
  # Set the priority of the interrupt associated with this Task
  case irqMod4
    of 0: prioReg.PRI_N0(nvicPrio).write()
    of 1: prioReg.PRI_N1(nvicPrio).write()
    of 2: prioReg.PRI_N2(nvicPrio).write()
    of 3: prioReg.PRI_N3(nvicPrio).write()
  # Enable the interrupt associated with this Task
  iserReg = irqBitf
  CRIT_EXIT()

  # Store these values for later use
  self.irqDiv32 = irqDiv32
  self.irqBitf = irqBitf

func runForever*(appOnStart: proc) {.noreturn.} =
  const writeKey = 0x05FA
  SCB.AIRCR
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
# proc lock*(ceiling: TaskPrio): LockKey =
#   let nvicPrio: NvicPrio = ceiling
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
