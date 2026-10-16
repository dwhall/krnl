## Copyright 2026 Dean Hall See LICENSE for details
##
## KRNL Actr operations
##

import armv7m/core
import plat, proj
import ../krnl_intf/[effects, event, signal]

type
  ## An Actr is an active object with an event handler that processes events
  ## serialized in FIFO fashion in its event queue.  An Actr can emit events,
  ## spawn child Actrs and change its event handler for the next event.
  ## Changing the event handler is how to implement a state machine.
  ## The irqNmbr is a unique value used to index into
  ## the interrupt handler array in krnl's VectorTable.
  ## An actr priority must never be more urgent than a hardware interrupt
  ## so that the actr's dispatchIsr always tail-chains after a hardware ISR
  ## (which may postEvent to the actr) rather than preempting it.
  Actr* = object of RootObj
    eventHandler: EventHandler
    eventQueue: seq[Event]
    # children: seq[Actr] # TODO: future work
    irqNmbr: IrqNmbr
    priority: ActrPriority

  EventHandler* =
    proc(self: var Actr, sig: Signal, val: EventValue): HandlerReturn {.nimcall.}

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

  ## 0 is the lowest priority.  The NVIC has 2^nvicPriorityBits levels;
  ## the most urgent level is reserved for device ISRs, leaving the rest for actrs.
  ActrPriority* = 0 .. ((1 shl plat.nvicPriorityBits()) - 2)

proc newActr*(
    self: var Actr, evntQueLen: uint8, priority: ActrPriority, handler: EventHandler
) =
  ## Returns an Actr with an event queue allocated to the given length.
  ## The irqNmbr field is set when the Actr is registered with the kernel.
  self.eventQueue = newSeqOfCap[Event](evntQueLen)
  self.priority = priority
  self.eventHandler = handler

proc `=copy`(
  dst: var Actr, src: Actr
) {.error: "Copying an Actr is prohibited because its address is given to krnl.".}

func priority*(self: Actr): ActrPriority =
  self.priority

func eventHandler*(self: Actr): EventHandler =
  self.eventHandler

func irqNmbr*(self: Actr): IrqNmbr =
  self.irqNmbr

func `irqNmbr=`*(self: var Actr, nmbr: IrqNmbr) =
  self.irqNmbr = nmbr

func popEvent*(self: var Actr): Event =
  ## Pops the next event from the actr's event queue
  ## NOTE: The caller MUST be in a critical section in privileged mode
  result = self.eventQueue[0]
  self.eventQueue.delete(0)

func addEvent*(self: var Actr, e: sink Event) =
  ## Adds an event to the actr's event queue
  ## NOTE: The caller MUST be in a critical section in privileged mode
  self.eventQueue.add(e)
