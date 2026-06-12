import std/unittest

import types, krnl
import ringque

proc init[N](self: var Task[N], e: Evnt) =
  discard e

suite "Event":
  test "Event type SHOULD exist":
    check compiles(Evnt(sig: 0, val: 0'u32))

  test "posting an event":
    var eventQue = RingQue[8'u8, uint32]()
    # var t = Task[uint32](eventQue: addr eventQue, init: init, dispatch: init)
    # let e = Evnt(sig: 42, val: 24'u32)
    # t.post(e)
    check len(eventQue) == 0

  teardown:
    discard
