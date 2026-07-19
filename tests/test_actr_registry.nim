## Copyright 2026 Dean Hall See LICENSE for details

import unittest2
import actr, irqnmbr

# module under test:
import actr_registry

test "the ActrRegistry type SHOULD exist":
  check compiles ActrRegistry

test "get from an empty registry SHOULD assert":
  let
    r = ActrRegistry()
  expect Defect:
    discard r.getActr(0)

test "SHOULD be able to register an actor":
  var r = ActrRegistry()
  let
    a = Actr[4]()
    n = IrqNmbr(12)
  r.registerActr(addr a, n)

test "SHOULD be able to get a registered actor":
  var r = ActrRegistry()
  let
    a = Actr[4]()
    n = IrqNmbr(12)
  r.registerActr(addr a, n)
  let aa = r.getActr(12)
  check addr(a) == aa

test "getting an unregisered irqNmbr should assert":
  var r = ActrRegistry()
  let
    a = Actr[4]()
    n = IrqNmbr(12)
  r.registerActr(addr a, n)
  expect Defect:
    discard r.getActr(99)
