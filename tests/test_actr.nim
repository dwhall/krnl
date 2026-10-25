## Copyright 2026 Dean Hall See LICENSE for details

import unittest2
import event

# module under test:
include ../src/krnl_impl/actr # not krnl_intf/actr

test "SHOULD be able to declare an Actr":
  check compiles (var a: Actr)

test "SHOULD be able to init an Actr":
  var a: Actr
  check compiles a.initActr(8, 3.ActrPriority, nil)

test "SHOULD be able to set the interrupt number field":
  var a: Actr
  a.initActr(3, 5.ActrPriority, nil)
  a.irqNmbr = 42
  check a.irqNmbr == 42

test "SHOULD be able to get the priority":
  var a: Actr
  a.initActr(3, 6.ActrPriority, nil)
  check a.priority.int == 6

test "SHOULD be able to add an event":
  let s = Sig("a.b.c", 123)
  var a: Actr
  a.initActr(3, 5.ActrPriority, nil)
  a.addEvent(Event(sig: s, val: 880))
  a.addEvent(Event(sig: s, val: 881))
  a.addEvent(Event(sig: s, val: 882))
  let e = a.popEvent()
  check e.val == 880

test "SHOULD be able to pop an event":
  let s = Sig("a.b.c", 123)
  var a: Actr
  a.initActr(3, 5.ActrPriority, nil)
  a.addEvent(Event(sig: s, val: 990))
  a.addEvent(Event(sig: s, val: 991))
  a.addEvent(Event(sig: s, val: 992))
  discard a.popEvent()
  let e = a.popEvent()
  check e.val == 991
