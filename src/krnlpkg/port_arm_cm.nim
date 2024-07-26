# krnl_arm_cm: Target-specific implementation for KRNL
#
# Copyright 2024 Dean Hall See LICENSE for details
#

import std/bitops


var nvicPrioShift: uint8  # FIXME: should use TaskPrio type

template TASK_PEND(self: typed): untyped =
  self.nvic_pend = self.nvic_irq

# This did not work, so Task has a "when buildTarget" block as a workaround
# template TASK_ATTRS() {.dirty inject.} =
#   nvic_pend: uint32
#   nvic_irq: uint32

func CRIT_ENTRY {.inline.} =
  asm "cpsid i"

func CRIT_EXIT {.inline.} =
  asm "cpsie i"

func runForever {.noreturn.} =
  while true:
      asm "__wfi"

func CRIT_STAT {.inline.} =
  discard

proc init =
  # Determine the number of NVIC priority bits by writing 0xFF to
  # the NIVIC IP register for PendSV and then reading back the
  # result, which has only the implemented bits set.
  # FIXME:
  # let tmp = SCB.SYSPRI[3]
  # SCB.SYSPRI[3] = bitor(SCB.SYSPRI[3], (0xFFu shl 16'u))
  # let prio = bitand((SCB.SYSPRI[3] shr 16'u), 0xFF'u)
  # SCB.SYSPRI[3] = tmp
  var tmp = 0'u8  # REMOVE
  var prio = 0'u

  for tmp in 0'u..8'u:
    if bitand(prio, (1'u shl tmp)) != 0:
      break
  nvicPrioShift = tmp
  # TODO: compare against the value we get from the SVD file

  when defined(ARM_FP):
    # Enable the FPU's automatic state preservation and lazy stacking
    FPU.FPCCR = bitor(FPU.FPCCR, (1'u shl 30), (1'u shl 31))

proc start =
  # Set the NVIC priority grouping to default 0
  # FIXME:
  # var tmp = SCB.AIRCR
  # tmp = tmp bitand bitnot(bitor((0xFFFF'u shl 16), (0x07'u shl 8)))
  # SCB.AIRCR = bitor((0x05FA'u shl 16), tmp)
  discard

proc setPrio(self: var Task, prio:TaskPrio) =
  # DBC_REQUIRE(200, self.nvic_irq != 0)
  # DBC_REQUIRE(201, prio <= (0xff'u shr nvic_prio_shift))

  # Convert the SST direct priority (1,2,..) to NVIC priority...
  let nvic_prio = ((0xFF'u shr nvic_prio_shift) + 1'u - prio) shl nvic_prio_shift

  CRIT_STAT
  CRIT_ENTRY()

  # Set the Task priority of the associated IRQ
  var tmp = NVIC_IP[self.nvic_irq shr 2'u]
  tmp = bitand(tmp, bitnot(0xFF'u shl (bitand(self.nvic_irq, 3'u) shl 3'u)))
  tmp = bitor(tmp, nvic_prio shl (bitand(self.nvic_irq, 3'u) shl 3'u))
  NVIC_IP[self.nvic_irq shr 2'u] = tmp

  # Enable the IRQ associated with the Task
  NVIC_EN[self.nvic_irq shr 5'u] = (1'u shl (self.nvic_irq & 0x1F'u))
  CRIT_EXIT()

  # Store the address of NVIC_PEND address and the IRQ bit
  self.nvic_pend = NVIC_PEND[self.nvic_irq shr 5'u]   # FIXME? was: &NVIC_PEND
  self.nvic_irq = (1'u shl bitand(self.nvic_irq, 0x1F'u))
