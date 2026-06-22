## Copyright 2026 Dean Hall See LICENSE for details
##
## Signal Registry for KRNL
##
## KRNL employs a publish/subscribe system to allow an actr
## to subscribe to the signals in which it has interest.
## This module provides the subscription registry.
##
## Implementation note:  The number of signals in the system
## likely exceeds 256.  The number of actrs is limited
## to the number of interrupt slots in the vector table.
## We use a hash table to hold the subscription registry.
## The table is indexed by the signal.
## The value is a bitflags of the interrupt slot numbers,
## where the interrupt number uniquely identifies one actr.
##

import std/tables
import bitflags, types

## Nb is the number of bits in the bitflags, which should be the number of
## interrupts in the system rounded up to the nearest multiple of 32
type SignalRegistry[Nb: static int] = Table[Signal, Bitflags[Nb]]

proc newRegistry*[Nb](): SignalRegistry[Nb] =
  Table[Signal, Bitflags[Nb]]()

proc contains*[Nb](registry: SignalRegistry[Nb], sig: Signal): bool =
  registry.hasKey(sig)

proc register*[Nb](registry: var SignalRegistry[Nb], sig: Signal) =
  ## Registers a signal in the registry if it doesn't already exist
  assert sig notin registry, "Signal already registered"
  registry[sig] = Bitflags[Nb]()

proc subscribe*[Nb](
    registry: var SignalRegistry[Nb], sig: Signal, irqNmbr: InterruptNmbr
) =
  ## Subscribes to a signal.  The given interrupt number will be scheduled
  ## to run when the signal is published.
  assert sig in registry, "Signal not registered"
  registry[sig].incl(irqNmbr.uint16)

proc unsubscribe*[Nb](
    registry: SignalRegistry[Nb], sig: Signal, irqNmbr: InterruptNmbr
) =
  ## Unsubscribes from a signal
  registry[sig].excl(irqNmbr.uint16)

iterator pairs*[Nb](
    registry: SignalRegistry[Nb], sig: Signal
): tuple[key: uint16, val: uint32] =
  ## Yields all bitflags for the given signal as (wordIdx, bitflags.uint32)
  if sig in registry:
    let bitflags = registry[sig]
    var idx = 0'u16
    for bf in bitflags:
      yield (idx, bf)
      inc idx
