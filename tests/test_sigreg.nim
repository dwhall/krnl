## Copyright 2026 Dean Hall See LICENSE for details

import unittest2

# module under test:
include signal_registry

test "SHOULD be able to create a signal registry":
  check compiles newRegistry[64]()

test "SHOULD include subscribed actr in signal's subscriber set":
  var r = newRegistry[64'u16]()
  let sig: Signal = 42
  r.register(sig)
  let actr = Actr()
  r.subscribe(sig, actr.irqNmbr)
  check actr.irqNmbr.uint16 in r[sig]

test "SHOULD allow multiple actrs to subscribe to the same signal":
  var r = newRegistry[64'u16]()
  let sig: Signal = 100
  r.register(sig)
  let actr1 = Actr()
  let actr2 = Actr()
  r.subscribe(sig, actr1.irqNmbr)
  r.subscribe(sig, actr2.irqNmbr)
  check actr1.irqNmbr.uint16 in r[sig]
  check actr2.irqNmbr.uint16 in r[sig]
