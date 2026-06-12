## Copyright 2026 Dean Hall See LICENSE for details

import unittest2

# module under test:
include signal_registry

test "SHOULD be able to create a signal registry":
  check compiles newRegistry[64]()

test "SHOULD include subscribed task in signal's subscriber set":
  var r = newRegistry[64'u16]()
  let sig: Signal = 42
  r.register(sig)
  let task = Task()
  r.subscribe(sig, task.irqNmbr)
  check task.irqNmbr.uint16 in r[sig]

test "SHOULD allow multiple tasks to subscribe to the same signal":
  var r = newRegistry[64'u16]()
  let sig: Signal = 100
  r.register(sig)
  let task1 = Task()
  let task2 = Task()
  r.subscribe(sig, task1.irqNmbr)
  r.subscribe(sig, task2.irqNmbr)
  check task1.irqNmbr.uint16 in r[sig]
  check task2.irqNmbr.uint16 in r[sig]
