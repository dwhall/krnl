## Copyright 2026 Dean Hall See LICENSE for details

import unittest2

# module under test:
include signal_registry

test "SHOULD be able to create a signal registry":
  check compiles newRegistry[64]()

test "SHOULD include subscribed task in signal's subscriber set":
  let reg = newRegistry[64]()
  let sig: Signal = 42
  let task: TaskId = 7
  reg.subscribe(sig, task)
  check task.uint16 in reg[sig]

test "SHOULD allow multiple tasks to subscribe to the same signal":
  let reg = newRegistry[64]()
  let sig: Signal = 100
  let task1: TaskId = 3
  let task2: TaskId = 15
  reg.subscribe(sig, task1)
  reg.subscribe(sig, task2)
  check task1.uint16 in reg[sig]
  check task2.uint16 in reg[sig]
