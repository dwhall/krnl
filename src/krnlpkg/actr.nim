## Copyright 2026 Dean Hall See LICENSE for details
##
## KRNL Actr operations
##

import armv7m/[core, sig]
import event, signal
import plat, proj

type
  ## An Actr is an active object with an event handler that processes events
  ## serialized in FIFO fashion in its event queue.  An Actr can emit events,
  ## spawn child Actrs and change its event handler for the next event.
  ## Changing the event handler is how to implement a state machine.
  ## The irqNmbr is a unique value used to index into
  ## the interrupt handler array in krnl's VectorTable.
  ## An actr priority must never be more urgent than a hardware interrupt
  ## so that the actr's dispatchIsr always tail-chains after a hardware ISR
  ## (which may post to the actr) rather than preempting it.
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

  ActrPriority* = 0 .. (0xFF shr plat.nvicPriorityBits()) # 0 is the lowest priority

proc initActr*(
    self: var Actr, evntQueLen: uint8, priority: ActrPriority, handler: EventHandler
) =
  ## Returns an Actr with an event queue allocated to the given length.
  ## The irqNmbr field is not initialized here;
  ## it is set when the Actr is registered with the kernel.
  self.eventQueue = newSeqOfCap[Event](evntQueLen)
  self.priority = priority
  # The actr's eventHandler must be halfword aligned (bit 0 clear)
  # on exception return (when we set the frame.pc in dispatchIsrBody).
  # So .eventHandler is private and can only be set here where alignment is forced.
  assert (cast[uint32](addr handler) and 1'u32) == 0'u32,
    "Expect Thumb2 func pointer alignment"
  self.eventHandler = handler

func setIrqNmbr*(self: var Actr, irqNmbr: IrqNmbr) =
  self.irqNmbr = irqNmbr

func priority*(self: Actr): ActrPriority =
  self.priority

func eventHandler*(self: Actr): EventHandler =
  self.eventHandler

func post*(self: var Actr, e: sink Event) =
  ## Posts an event to the actr and schedules the actr for execution
  ## within a critical section
  ## NOTE: The caller MUST be in privileged mode
  self.eventQueue.add(e)
  sig.SIG.STIR.INTID(self.irqNmbr.uint32)

func popEvent*(self: var Actr): Event =
  ## Pops the next event from the actr's event queue
  ## NOTE: The caller MUST be in a critical section in privileged mode
  result = self.eventQueue[0]
  self.eventQueue.delete(0)
