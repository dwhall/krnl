## Copyright 2026 Dean Hall See LICENSE for details
##
## KRNL Actr operations
##

import armv7m/[core, sig]
import event, irqnmbr, priority, signal
import proj

type
  ## An Actr is an active object with an event handler that processes events
  ## serialized in FIFO fashion in its event queue.  An Actr can emit events,
  ## spawn child Actrs and change its event handler for the next event.
  ##
  ## Generic parameter N is the count of items in the event queue.
  ## Child Actrs have no event queue because they process
  ## the event directly dispatched from the parent.
  ## The irqNmbr field also serves as an index into the interruptHandler
  ## array in the VectorTable, which also implies it is a unique value
  Actr* = ref object of RootObj
    eventHandler*:
      proc(self: Actr, sig: Signal, val: EventValue): HandlerReturn {.nimcall.}
    eventQueue: seq[Event]
    # children: seq[Actr[0'u8]] # TODO: future work
    irqNmbr: IrqNmbr
    priority: ActrPriority

  ## An Actr has at least one EventHandler, which may optionally transition
  ## to another EventHandler in response to an Event; forming a state machine.
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

proc newActr*(evntQueLen: uint8, prio: ActrPriority): Actr =
  ## Returns an Actr with an event queue allocated to the given length.
  ## The irqNmbr field is not initialized here;
  ## it is set when the Actr is registered with the kernel.
  result.eventQueue = newSeqOfCap[Event](evntQueLen)
  result.priority = prio

func setIrqNmbr*(self: var Actr, irqNmbr: IrqNmbr) =
  self.irqNmbr = irqNmbr

template CRIT_ENTER() =
  disableIrq()

template CRIT_EXIT() =
  enableIrq()

template schedule(self: Actr) =
  ## Schedules the actr for execution by pending its interrupt in the NVIC
  # NOTE: The caller MUST be in a critical section in privileged mode
  sig.SIG.STIR.INTID(self.irqNmbr.uint32)

func post*(self: var Actr, e: Event) =
  ## Posts an event to the actr and schedules the actr for execution
  ## within a critical section
  # NOTE: The caller MUST be in privileged mode
  CRIT_ENTER()
  self.eventQueue.add(e)
  self.schedule()
  CRIT_EXIT()

func popEvent*(self: var Actr): Event =
  ## Pops the next event from the actr's event queue
  # NOTE: The caller MUST be in a critical section in privileged mode
  result = self.eventQueue[0]
  self.eventQueue.delete(0)
