## Copyright 2026 Dean Hall See LICENSE for details

import unittest2

# module under test:
include signal_registry

test "SHOULD be able to create a signal registry":
  check compiles newRegistry[64'u16]()

test "SHOULD include subscribed task in signal's subscriber set":
  let reg = newRegistry[64'u16]()
  let sig: Signal = 42
  let task = Task[8, uint32]()
  reg.subscribe(sig, task.irqNmbr)
  check task.irqNmbr in reg[sig]

test "SHOULD allow multiple tasks to subscribe to the same signal":
  let reg = newRegistry[64'u16]()
  let sig: Signal = 100
  let task1 = Task[8, uint32]()
  let task2 = Task[8, uint32]()
  reg.subscribe(sig, task1.irqNmbr)
  reg.subscribe(sig, task2.irqNmbr)
  check task1.irqNmbr in reg[sig]
  check task2.irqNmbr in reg[sig]
