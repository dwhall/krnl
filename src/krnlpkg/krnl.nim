#!fmt: off
## Copyright 2024 Dean Hall See LICENSE for details
##
## KRNL: an event-based microkernel with memory protection for ARM Cortex-M devices
## This takes ideas from Miro Samek's Super-Simple-Tasker and QPc
##   https://github.com/QuantumLeaps/
##

import armv7m/[core, fp, nvic, scb]
import nrf52840/device
import types, task

type
  Handler = proc(self: var Task, e: Evnt)
  LockKey = uint32

const nvicPrioShift = cpu.nvicPrioBits.uint32

template CRIT_ENTER() =
  disableIrq()

template CRIT_EXIT() =
  enableIrq()

# Forward declarations
proc setPrio(self: var Task, prio: TaskPrio)

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

func startTask*[N, T](self: var Task[N, T], prio: TaskPrio, initEvnt: Evnt) =
  # TODO: init priority queue?
  self.setPrio(prio)
  self.init(initEvnt)

proc setPrio(self: var Task, prio: TaskPrio) =
  ## Sets the this task's interrupt's priority
  ## and enables the interrupt in the NVIC
  assert self.irqNmbr > 0'u8
  assert prio <= (0xFF'u8 shr nvicPrioShift)

  let (irqDiv4, irqMod4) = divmod(self.irqNmbr, 4'u8)
  let iprReg = NVIC.NVIC_IPR[irqDiv4]

  let (irqDiv32, irqMod32) = divmod(self.irqNmbr, 32'u8)
  let irqBitf = 1'u32 shl irqMod32
  let iserReg = NVIC.NVIC_ISER[irqDiv32]

  let nvicPrio: NvicPrio = prio # implicitly calls the converter
  CRIT_ENTER()
  # Set the priority of the interrupt associated with this Task
  case irqMod4
    of 0: iprReg.PRI_N0(nvicPrio).write()
    of 1: iprReg.PRI_N1(nvicPrio).write()
    of 2: iprReg.PRI_N2(nvicPrio).write()
    of 3: iprReg.PRI_N3(nvicPrio).write()
  # Enable the interrupt associated with this Task
  iserReg = irqBitf
  CRIT_EXIT()

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
