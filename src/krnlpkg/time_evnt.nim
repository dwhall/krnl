## Copyright 2026 Dean Hall See LICENSE for details
##
## KRNL timer events
##

import types

type
  TCtr = uint16

  TimeEvnt* = ref object of Evnt
    next: TimeEvnt
    task: Task
    ctr: TCtr
    interval: TCtr

proc newTimeEvnt*(head: TimeEvnt, sig: Signal, task: Task): TimeEvnt =
  # f.k.a. ctor
  ## Inserts a new TimeEvnt at the head of the linked list
  # implicit allocation of TimeEvnt node in variable, result
  result.sig = sig
  result.task = task
  result.next = head
  head = result

func arm*(self: var TimeEvnt, ctr: TCtr, interval: TCtr = 0) =
  ## Arms the TimeEvnt with the given counter value
  ## The interval argument defaults to zero, which arms a one-shot timer.
  ## Set interval to non-zero for a repeating timer.
  CRIT_ENTER()
  self.ctr = ctr
  self.interval = interval
  CRIT_EXIT()

func disarm*(self: var TimeEvnt): bool =
  ## Disarms the given timer.  The timer remains in the list.
  CRIT_ENTER()
  result = (self.ctr != 0)
  self.ctr = 0
  self.interval = 0
  CRIT_EXIT()

# usually called by the SysTick ISR handler
proc tick*(head: ref TimeEvnt) =
  ## For each timer event in the list:
  ##    If the counter is 0, do nothing.  The counter is expired.
  ##    If the counter is 1, dispatches the event to its task
  ##    and resets the counter with the interval value.
  ##    Otherwise, decrements the counter by one.
  var t = head
  while t != nil:
    CRIT_ENTER()
    if t.ctr == 0:
      CRIT_EXIT()
    elif t.ctr == 1:
      t.ctr = t.interval
      CRIT_EXIT()
      t.task.post(t)
    else:
      dec t.ctr
      CRIT_EXIT()
    t = t.next
