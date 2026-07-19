## Copyright 2026 Dean Hall See LICENSE for details
##
## KRNL Actr operations
##

import armv7m/[core, sig]
import event, irqnmbr, priority, ringque

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
  Actr*[N: static uint8] = object of RootObj
    eventHandler: proc(self: Actr[N], event: Event): HandlerReturn {.nimcall.}
    eventQueue: RingQue[N, Event]
    # children: seq[Actr[0'u8]] # TODO: future work
    irqNmbr*: IrqNmbr
    priority: ActrPriority

  ## An Actr has at least one EventHandler, which may optionally transition
  ## to another EventHandler in response to an Event; forming a state machine.
  EventHandler*[N: static uint8] =
    proc(self: Actr[N], event: Event): HandlerReturn {.nimcall.}

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

template CRIT_ENTER() =
  disableIrq()

template CRIT_EXIT() =
  enableIrq()

template schedule(self: Actr) =
  ## Schedules the actr for execution by pending its interrupt in the NVIC
  # NOTE: The caller MUST be in a critical section in privileged mode
  SIG.STIR.INTID(self.irqNmbr)

proc activate*(self: var Actr) =
  ## Pops an event within a critical section and calls the actr's event handler.
  ## If the actr's event queue is not empty after popping,
  ## the actr is scheduled for execution again.
  # NOTE: MUST only be called when the actr has an event in its queue
  # NOTE: The caller MUST be in privileged mode
  assert self.eventQue.len() > 0'u8
  CRIT_ENTER()
  let e = self.eventQue.pop()
  if self.eventQue.len() > 0:
    self.schedule()
  CRIT_EXIT()
  self.dispatch(e) # actr's event handler

func post*(self: var Actr, e: Event) =
  ## Posts an event to the actr and schedules the actr for execution
  ## within a critical section
  # NOTE: The caller MUST be in privileged mode
  CRIT_ENTER()
  self.eventQue.add(e)
  self.schedule()
  CRIT_EXIT()

func setIrq*(self: var Actr, irq: uint8) =
  self.irqNum = irq
