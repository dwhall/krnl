## Copyright 2026 Dean Hall See LICENSE for details
##
## KRNL Actr operations
##

import std/deques
import armv7m/core
import plat, proj
import ../krnl_intf/[effects, event, signal]

type
  ## An EventHandler takes the concrete Actr subtype T it was written for.
  ## Must be declared before Actr, whose field instantiates it,
  ## or the compiler rejects every EventHandler[T] as an invalid type.
  EventHandler[T: Actr] = proc(
    self: var T, sig: Signal, val: EventValue
  ): HandlerReturn {.nimcall, forbids: [PrivilegedModeEffect].}

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
    eventHandler: EventHandler[Actr]
    eventQueue: Deque[Event]
    # children: seq[Actr] # TODO: future work
    irqNmbr: IrqNmbr
    priority: ActrPriority

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

proc initActr*[T: Actr](
    self: var T,
    evntQueLen: int,
    priority: ActrPriority,
    handler: EventHandler[T],
) =
  ## Returns an Actr with an event queue allocated to the given length.
  ## The irqNmbr field is set when the Actr is registered with the kernel.
  ## Casting the handler to EventHandler[Actr] is safe because
  ## a var T is passed as a pointer and T's Actr part is at offset 0.
  self.eventQueue = initDeque[Event](evntQueLen)
  self.priority = priority
  self.eventHandler = cast[EventHandler[Actr]](handler)

proc `=copy`(
  dst: var Actr, src: Actr
) {.error: "Copying an Actr is prohibited because its address is given to krnl.".}

func priority*(self: Actr): ActrPriority =
  self.priority

func eventHandler*(self: Actr): EventHandler[Actr] =
  self.eventHandler

func irqNmbr*(self: Actr): IrqNmbr =
  self.irqNmbr

func `irqNmbr=`*(self: var Actr, nmbr: IrqNmbr) =
  self.irqNmbr = nmbr

func popEvent*(self: var Actr): Event =
  ## Pops the next event from the actr's event queue
  ## NOTE: The caller MUST be in a critical section in privileged mode
  if self.eventQueue.len == 0: ## TODO: apply unified error handling instead
    return default(Event)
  self.eventQueue.popLast()

func addEvent*(self: var Actr, e: sink Event) =
  ## Adds an event to the actr's event queue
  ## NOTE: The caller MUST be in a critical section in privileged mode
  self.eventQueue.addFirst(e)
