# krnl_arm_cm: Target-specific implementation for KRNL
#
# Copyright 2024 Dean Hall See LICENSE for details
#

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
