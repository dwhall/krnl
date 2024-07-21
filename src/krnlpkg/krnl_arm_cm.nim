# krnl_arm_cm: Target-specific implementation for KRNL
#
# Copyright 2024 Dean Hall See LICENSE for details
#

import krnl

type
  ArmCmTask[T] = object of Task[T]
    nvic_pend: uint32
    nvic_irq: uint32

func TASK_PEND[T](self: var Task[T]) {.inline.} =
  self.nvic_pend = self.nvic_irq

func CRIT_ENTRY {.inline.} =
  asm "cpsid i"

func CRIT_EXIT {.inline.} =
  asm "cpsie i"

func runForever {.noreturn.} =
  while true:
      asm "__wfi"
