import std/unittest

import krnl

suite "test RingQue, the circular queue module":
  test "declaring a new que should work":
    var q = RingQue[32, int]()
    check compiles RingQue[32, int]()
