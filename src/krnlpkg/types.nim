## Copyright 2026 Dean Hall See LICENSE for details
##
## KRNL broadly used types and converters

import plat, proj, ringque

type
  ExceptionNmbr* = 1 .. 16 + plat.platInterruptCount # ARM Exception number
  InterruptNmbr* = 0 .. plat.platInterruptCount - 1 # ARM Interrupt number

  ActrPriority* = uint8 # 0 is the lowest priority
  NvicPriority* = uint8 # 0 is the highest priority

  ## An Actr is an active object with an event handler that processes events
  ## serialized in FIFO fashion in its event queue.  An Actr can emit events,
  ## spawn child Actrs and change its event handler for the next event.
  ##
  ## N is count of items in the event queue.
  ## Child Actrs have no event queue because they process
  ## the event directly dispatched from the parent.
  ## The irqNmbr field also serves as an index into the interruptHandler
  ## array in the VectorTable; and also as a unieq identifier
  Actr*[N: static uint8] = object of RootObj
    eventHandler: EventHandler
    eventQueue: RingQue[N, Event]
    children: seq[Actr[0]]
    irqNmbr*: InterruptNmbr
    priority: ActrPriority

  ## The Signal is a value that discriminates an Event.
  Signal* = uint32

  ## Events are the fundamental and primary communication between Actrs.
  ## Events are posted from one Actr to a child Actr,
  ## or published so that every Actr might receive the Event.
  ## EventValue is a project-defined datatype.
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
  assert exnNmbr.int >= 16, "Exceptions lower than 16 are not interrupts"
  InterruptNmbr(exnNmbr.int - 16)

converter toNvicPriority*(prio: ActrPriority): NvicPriority =
  ## Converts ActrPriority where 0 is the lowest priority
  ## to NvicPriority where 0 is the highest priority
  NvicPriority(
    ((0xFF'u32 shr plat.platNvicPriorityBits) + 1'u32 - prio) shl
      plat.platNvicPriorityBits
  )
