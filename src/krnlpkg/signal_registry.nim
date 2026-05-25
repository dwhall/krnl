## Copyright 2026 Dean Hall See LICENSE for details
##
## Signal Registry for KRNL
##
## KRNL employs a publish/subscribe system to allow a task
## to subscribe to the signals in which it has interest.
## This module provides the registry.
##
## Implementation note:  The number of signals in the system
## may number in the thousands.  The number of tasks is limited
## to the number of unused interrupt slots in the vector table.
## We use a hash table keyed by the signal value to lookup a
## bitset of the tasks subscribed to that signal.

import std/tables
import bitfield, types

type
  TaskId = ExceptionNmbr
  TaskIdSet[N: static uint16] = Bitfield[N]
  SignalRegistry[N: static uint16] = Table[Signal, TaskIdSet[N]]

let isEmptyTaskIdSet = TaskIdSet[0]()

proc newRegistry*[N: static uint16](): ref SignalRegistry[N] =
  newTable[Signal, TaskIdSet[N]]()

proc subscribe*[N: static uint16](
    registry: ref SignalRegistry[N], sig: Signal, task: TaskId
) =
  ## Subscribes a task to a signal
  if sig notin registry:
    registry[sig] = Bitfield()
  registry[sig].incl(task)

proc unsubscribe*[N: static uint16](
    registry: ref SignalRegistry[N], sig: Signal, task: TaskId
) =
  ## Unsubscribes a task from a signal
  if sig in registry:
    registry[sig].excl(task)

iterator pairs*[N: static uint16](
    registry: ref SignalRegistry[N], sig: Signal
): tuple[key: uint16, val: uint32] =
  ## Returns each 32-bit field of the task ID bitset for the given signal,
  ## where the key is the field index and the value is the field itself
  if sig in registry:
    let reg = registry[sig]
    for i in 0'u8 ..< fields:
      yield (i, reg[i])
