## Copyright 2026 Dean Hall See LICENSE for details
##
## KRNL broadly used types and converters

import plat, proj, signal

type
  ExceptionNmbr* = 1 .. 16 + plat.platInterruptCount # ARM Exception number
  InterruptNmbr* = 0 .. plat.platInterruptCount - 1 # ARM Interrupt number

  ActrPriority* = uint8 # 0 is the lowest priority
  NvicPriority* = uint8 # 0 is the highest priority

  ## Events are the fundamental and primary communication between Actrs.
  ## Events are posted from one Actr to a child Actr,
  ## or published so that every Actr might receive the Event.
  ## EventValue is a project-defined datatype.
  Event* = object
    sig*: Signal
    val*: EventValue

converter toInterruptNumber*(exnNmbr: ExceptionNmbr): InterruptNmbr =
  ## Converts an exception number to an interrupt number
  assert exnNmbr.int >= 16, "Exceptions lower than 16 are not interrupts"
  InterruptNmbr(exnNmbr.int - 16)

converter toNvicPriority*(prio: ActrPriority): NvicPriority =
  ## Converts ActrPriority where 0 is the lowest priority
  ## to NvicPriority where 0 is the highest priority
  NvicPriority(
    ((0xFF'u32 shr plat.platNvicPriorityBits) + 1'u32 - prio) shl
      plat.platNvicPriorityBits
  )
