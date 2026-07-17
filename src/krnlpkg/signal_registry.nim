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
import bitflags, namespace, signal, vectortable

type
  SigPubToken* = uint32 # TODO: make distinct?
  SignalRegistry*[Nb: static int] = object
    publishers: Table[SigPubToken, SigTuple]
    subscribers: Table[Signal, Bitflags[Nb]]

proc contains*[Nb](self: SignalRegistry[Nb], sig: SigTuple): bool =
  self.publishers.hasVal(sig)

proc registerSignals*[Nb](
    self: var SignalRegistry[Nb], nsHash: NamespaceHash32, maxSig: uint32
) =
  ## Registers a range signals from 0 .. maxSig in the registry
  self.publishers


proc subscribe*[Nb](
    self: var SignalRegistry[Nb], sig: SigTuple, irqNmbr: IrqNmbr
) =
  ## Subscribes to a signal.  The given interrupt number will be pended
  ## for activation when the signal is published.
  assert sig in registry, "Signal not registered"
  self.subscribers[sig].incl(irqNmbr.uint16)

proc unsubscribe*[Nb](
    self: var SignalRegistry[Nb], sig: SigTuple, irqNmbr: IrqNmbr
) =
  ## Unsubscribes from a signal
  self.subscribers[sig].excl(irqNmbr.uint16)

iterator pairs*[Nb](
    self: SignalRegistry[Nb], sig: Signal
): tuple[key: uint16, val: uint32] =
  ## Yields all bitflags for the given signal as (wordIdx, bitflags.uint32)
  if sig in self:
    let bitflags = self[sig]
    var idx = 0'u16
    for bf in bitflags:
      yield (idx, bf)
      inc idx
