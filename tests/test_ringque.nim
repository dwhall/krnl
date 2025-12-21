import std/unittest

import ringque

suite "test RingQue, the circular queue module":
  test "declaring a RingQue SHOULD work":
    check compiles(RingQue[2'u8, int]())

  test "cap() SHOULD return the statically declared capacity":
    var q: RingQue[4'u8, int]
    check q.cap == 4

  test "len() SHOULD return the length":
    var q = RingQue[4'u8, int]()
    check q.len == 0
    q.add(0)
    check q.len == 1

  test "add() SHOULD grow the queue":
    var q = RingQue[4'u8, int]()
    q.add(1)
    q.add(2)
    q.add(3)
    check q.len == 3

  test "add() SHOULD assert if the queue is full":
    var q = RingQue[4'u8, int]()
    q.add(1)
    q.add(2)
    q.add(3)
    q.add(4)
    expect IndexDefect:
      q.add(5)

  test "add() SHOULD allow wrap-around behavior to work correctly":
    var q = RingQue[4'u8, int]()
    q.add(1)
    q.add(2)
    q.add(3)
    discard q.pop()
    q.add(4)
    q.add(5)
    check q.len == 4
    check q.pop == 2

  test "pop() SHOULD shrink the queue":
    var q = RingQue[4'u8, int]()
    q.add(1)
    q.add(2)
    q.add(3)
    discard q.pop()
    check q.len == 2

  test "pop() SHOULD assert if the queue is empty":
    var q = RingQue[4'u8, int]()
    expect IndexDefect:
      discard q.pop()

  test "clear() SHOULD empty the queue":
    var q = RingQue[4'u8, int]()
    q.add(1)
    q.add(2)
    check q.len == 2
    q.clear()
    check q.len == 0

  test "full() SHOULD return false if the queue is not completely full":
    var q = RingQue[4'u8, int]()
    q.add(1)
    q.add(2)
    q.add(3)
    check not q.full

  test "full() SHOULD return true only if the queue is completely full":
    var q = RingQue[4'u8, int]()
    q.add(1)
    q.add(2)
    q.add(3)
    q.add(4)
    check q.full

  test "copying a RingQue SHOULD NOT compile":
    var q1 = RingQue[4'u8, int]()
    q1.add(1)
    q1.add(2)
    var q2 = RingQue[4'u8, int]()
    check not compiles(q2 = q1)
    discard q2

let q = newRingQue(4, int)
echo q
