## Copyright 2026 Dean Hall See LICENSE for details
##
## KRNL broadly used types and converters

import event_value, ringque

type
  ExceptionNmbr* = distinct uint16 # ARM Exception number
  InterruptNmbr* = distinct uint16 # ARM Interrupt number

  ActrPriority* = uint8 # 0 is the lowest priority
  NvicPriority* = uint8 # 0 is the highest priority

  ## An Actr is an active object with an event handler that processes
  ## events serialized in its event queue.  It can also spawn child Actrs.
  Actr*[N: static uint8] = object of RootObj
    eventHandler: EventHandler
    eventQueue: ptr RingQue[N, Event] # must be ptr; may be declared on the stack
    children: seq[Actr]
    irqNmbr*: InterruptNmbr # VectorTable index; also serves as a unique identifier
    priority: ActrPriority

  ## The Signal is a value that discriminates an Event.
  Signal* = uint32

  ## Events are the fundamental and primary communication between Actrs.
  ## Events are posted from one Actr to a child Actr,
  ## or published so that every Actr might receive the Event.
  Event* = object
    sig*: Signal
    val*: EventValue

  ## An Actr has at least one EventHandler, which may optionally transition
  ## to another EventHandler in response to an Event; forming a state machine.
  EventHandler* = proc(self: Actr, event: Event): HandlerReturn {.nimcall.}

  ## Every EventHandler returns a HandlerReturn code to indicate
  ## how the event was processed.
  HandlerReturn* = enum
    RetSuper
    RetUnhandled
    RetHandled
    RetIgnored
    RetEntry
    RetExit
    RetTransitioned

converter toInterruptNumber*(exnNmbr: ExceptionNmbr): InterruptNmbr =
  ## Converts an exception number to an interrupt number
  InterruptNmbr(exnNmbr.uint16 - 16'u16)

converter toNvicPriority(prio: ActrPriority): NvicPriority =
  ## Converts ActrPriority where 0 is the lowest priority
  ## to NvicPriority where 0 is the highest priority
  # TODO: const nvicPrioShift = cpu.nvicPriorityBits.uint32
  const nvicPrioShift = 4 # FIXME
  NvicPriority(((0xFF'u32 shr nvicPrioShift) + 1'u32 - prio) shl nvicPrioShift)
