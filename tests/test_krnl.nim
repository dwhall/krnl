import std/unittest

import krnl
import ringque

proc init[N, T](self: var Task[N, T], e: Evt[T]) =
  discard e

suite "Event":
  test "Event type SHOULD exist":
    check compiles(Evt[uint32](sig: 0, val: 0'u32))

  test "posting an event":
    var eventQue = RingQue[8'u8, uint32]()
    # var t = Task[uint32](eventQue: addr eventQue, init: init, dispatch: init)
    # let e = Evt[uint32](sig: 42, val: 24'u32)
    # t.post(e)
    check len(eventQue) == 0

  teardown:
    discard
