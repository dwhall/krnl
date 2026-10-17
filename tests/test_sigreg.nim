## Copyright 2026 Dean Hall See LICENSE for details

import unittest2
import bitflags # card, isEmpty for ActrSet

# module under test:
include ../src/krnl_impl/signal_registry # not krnl_intf/signal_registry

test "SHOULD be able to create a signal registry":
  check compiles SignalRegistry()

test "registerSignals SHOULD record the publisher's signal series":
  var r = SignalRegistry()
  r.registerSignals(NS32"one.two.three", 10)
  check r.publishers.len == 1

test "SHOULD include subscribed actr in signal's subscriber set":
  var r = SignalRegistry()
  let sig = Signal(42)
  let irq: IrqNmbr = 5
  r.subscribe(sig, irq)
  check irq in r.getSubscribersTo(sig)

test "SHOULD allow multiple actrs to subscribe to the same signal":
  var r = SignalRegistry()
  let sig = Signal(100)
  let irq1: IrqNmbr = 3
  let irq2: IrqNmbr = 40
  r.subscribe(sig, irq1)
  r.subscribe(sig, irq2)
  let subscribers = r.getSubscribersTo(sig)
  check irq1 in subscribers
  check irq2 in subscribers
  check subscribers.card == 2

test "SHOULD be able to iterate over a series of ActrSet":
  var r = SignalRegistry()
  let sig = Signal(42)
  r.registerSignals(NS32"one.two.three", 5)
  r.subscribe(sig, 1.IrqNmbr)
  r.subscribe(sig, 31.IrqNmbr)
  r.subscribe(sig, 33.IrqNmbr)
  r.subscribe(sig, 47.IrqNmbr)
  var n = 0
  for actrset in r.getSubscribersTo(sig).items():
    inc n
  check n > 0

test "unsubscribe SHOULD remove only that actr from the subscriber set":
  var r = SignalRegistry()
  let sig = Signal(42)
  let irq1: IrqNmbr = 20
  let irq2: IrqNmbr = 21
  r.subscribe(sig, irq1)
  r.subscribe(sig, irq2)
  r.unsubscribe(sig, irq1)
  check irq1 notin r.getSubscribersTo(sig)
  check irq2 in r.getSubscribersTo(sig)

test "unsubscribe from a signal with no subscribers SHOULD be harmless":
  var r = SignalRegistry()
  let irq: IrqNmbr = 7
  r.unsubscribe(Signal(42), irq)
  check r.getSubscribersTo(Signal(42)).isEmpty

test "a signal with no subscribers SHOULD have an empty subscriber set":
  let r = SignalRegistry()
  check r.getSubscribersTo(Signal(42)).isEmpty
