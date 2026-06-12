## Copyright 2026 Dean Hall See LICENSE for details
##
## KRNL broadly used types and converters

import event_value

type
  ExceptionNmbr* = distinct uint16 # ARM Exception number
  InterruptNmbr* = distinct uint16 # ARM Interrupt number

  ActrPriority* = uint8 # 0 is the lowest priority
  NvicPriority* = uint8 # 0 is the highest priority

  Signal* = int32
  Evnt* = object
    sig*: Signal
    val*: EventValue

  Actr* = object
    priority: ActrPriority
    irqNmbr*: InterruptNmbr # VectorTable slot; also serves as a unique identifier

converter toInterruptNumber*(exnNmbr: ExceptionNmbr): InterruptNmbr =
  ## Converts an exception number to an interrupt number
  InterruptNmbr(exnNmbr.uint16 - 16'u16)

converter toNvicPriority(prio: ActrPriority): NvicPriority =
  ## Converts ActrPriority where 0 is the lowest priority
  ## to NvicPriority where 0 is the highest priority
  # TODO: const nvicPrioShift = cpu.nvicPriorityBits.uint32
  const nvicPrioShift = 4 # FIXME
  NvicPriority(((0xFF'u32 shr nvicPrioShift) + 1'u32 - prio) shl nvicPrioShift)
