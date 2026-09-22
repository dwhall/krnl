## Copyright 2026 Dean Hall See LICENSE for details
##
## KRNL Actr operations
##

import armv7m/[core, sig]
import event, priority, signal
import plat, proj

type
  ## An Actr is an active object with an event handler that processes events
  ## serialized in FIFO fashion in its event queue.  An Actr can emit events,
  ## spawn child Actrs and change its event handler for the next event.
  ## Changing the event handler is how to implement a state machine.
  ## The irqNmbr is a unique value used to index into
  ## the interrupt handler array in krnl's VectorTable.
  Actr* = object of RootObj
    eventHandler*: EventHandler
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

proc initActr*(self: var Actr, evntQueLen: uint8, prio: ActrPriority) =
  ## Returns an Actr with an event queue allocated to the given length.
  ## The irqNmbr field is not initialized here;
  ## it is set when the Actr is registered with the kernel.
  self.eventQueue = newSeqOfCap[Event](evntQueLen)
  self.priority = prio

func setIrqNmbr*(self: var Actr, irqNmbr: IrqNmbr) =
  self.irqNmbr = irqNmbr

template schedule(self: Actr) =
  ## Schedules the actr for execution by pending its exception in the NVIC
  # NOTE: The caller MUST be in a critical section in privileged mode
  sig.SIG.STIR.INTID(self.irqNmbr.uint32)

func post*(self: var Actr, e: Event) =
  ## Posts an event to the actr and schedules the actr for execution
  ## within a critical section
  # NOTE: The caller MUST be in privileged mode
  self.eventQueue.add(e)
  self.schedule()

func popEvent*(self: var Actr): Event =
  ## Pops the next event from the actr's event queue
  # NOTE: The caller MUST be in a critical section in privileged mode
  result = self.eventQueue[0]
  self.eventQueue.delete(0)
