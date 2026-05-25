## Copyright 2026 Dean Hall See LICENSE for details
##
## Signal Registry for KRNL
##
## KRNL employs a publish/subscribe system to allow a task
## to subscribe to the signals in which it has interest.
## This module provides the subscription registry.
##
## Implementation note:  The number of signals in the system
## likely exceeds 256.  The number of tasks is limited
## to the number of interrupt slots in the vector table.
## We use a hash table to hold the subscription registry.
## The table is indexed by the signal.
## The value is a bitfield of the interrupt slot numbers,
## where the interrupt number uniquely identifies one task.
##

import std/tables
import bitfield, types

## N is the number of bits in the bitfield, which should be the number of
## interrupts in the system rounded up to the nearest multiple of 32
type SignalRegistry[Nb: static uint16] = Table[Signal, Bitfield[Nb]]

proc newRegistry*[Nb: static uint16](): ref SignalRegistry[Nb] =
  newTable[Signal, Bitfield[Nb]]()

proc subscribe*[Nb: static uint16](
    registry: ref SignalRegistry[Nb], sig: Signal, taskIrqNmbr: InterruptNmbr
) =
  ## Subscribes a task to a signal
  if sig notin registry:
    registry[sig] = Bitfield[Nb]()
  registry[sig].incl(taskIrqNmbr)

proc unsubscribe*[Nb: static uint16](
    registry: ref SignalRegistry[Nb], sig: Signal, taskIrqNmbr: InterruptNmbr
) =
  ## Unsubscribes a task from a signal
  if sig in registry:
    registry[sig].excl(taskIrqNmbr)

iterator pairs*[Nb: static uint16](
    registry: ref SignalRegistry[Nb], sig: Signal
): tuple[key: uint16, val: uint32] =
  ## Returns each 32-bit bitfield for the given signal
  if sig in registry:
    let bitfield = registry[sig]
    for i in 0'u8 ..< bitfield.len:
      yield (i, bitfield[i])
