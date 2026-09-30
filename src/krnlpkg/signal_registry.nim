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
## The value is a bitflags of the interrupt numbers,
## where the interrupt number uniquely identifies the actrs
## subscribed to the signal.
##

import std/tables
import actr_set, namespace, plat, signal

type
  SigPubToken* = uint32 # TODO: make distinct?
  SignalRegistry* = object
    publishers: Table[SigPubToken, SigSeries]
    subscribers: Table[Signal, ActrSet]

#proc contains*(self: SignalRegistry, sig: SigSeries): bool =
#  self.publishers.hasVal(sig)

func registerSignals*(
    self: var SignalRegistry, nsHash: NamespaceHash32, maxSig: uint32
) =
  ## Registers a range signals from 0 .. maxSig in the registry
  let token = SigPubToken(0) # TODO: generate a real token
  self.publishers[token] = SigSeries(nsHash: nsHash, maxSig: maxSig)

func subscribe*(self: var SignalRegistry, sig: Signal, irqNmbr: IrqNmbr) =
  ## Subscribes to a signal.  The given interrupt number will be pended
  ## for activation when the signal is published.
  self.subscribers[sig].incl(irqNmbr)

func unsubscribe*(self: var SignalRegistry, sig: Signal, irqNmbr: IrqNmbr) =
  ## Unsubscribes from a signal.  Harmless if no subscription exists.
  self.subscribers[sig].excl(irqNmbr)

func getSubscribersTo*(self: SignalRegistry, sig: Signal): ActrSet =
  ## The set of subscriber interrupt numbers for `sig` (default/empty if none).
  self.subscribers.getOrDefault(sig)
