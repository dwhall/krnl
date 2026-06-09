## Copyright 2026 Dean Hall See LICENSE for details

import unittest2

# module under test:
import bitflags

test "SHOULD be able to create a bitflags":
  check compiles Bitflags[32]()

test "cap SHOULD return the capacity of the bitflags":
  let bf1 = Bitflags[64]()
  check bf1.cap == 64
  let bf2 = Bitflags[88]()
  check bf2.cap == 96

test "SHOULD be able to include a flag in the bitflags":
  var bf = Bitflags[32]()
  check compiles bf.incl 5

test "SHOULD be able to check if a flag is in the bitflags":
  var bf = Bitflags[64]()
  bf.incl 55
  check 55 in bf

test "SHOULD be able to check if a flag is not in the bitflags":
  var bf = Bitflags[64]()
  bf.incl 55
  check 23 notin bf

test "SHOULD be able to exclude a flag from the bitflags":
  var bf = Bitflags[64]()
  check compiles bf.excl 55

test "SHOULD be able to check that a flag is excluded":
  var bf = Bitflags[64]()
  bf.incl 55
  bf.incl 0
  bf.excl 55
  check 55 notin bf

test "SHOULD be able to check that a flag is not excluded":
  var bf = Bitflags[64]()
  bf.incl 55
  bf.incl 0
  bf.excl 55
  check 0 in bf

test "SHOULD be able to check if the bitflags is empty":
  var bf = Bitflags[64]()
  check bf.isEmpty
  bf.incl 1
  check not bf.isEmpty
  bf.incl 55
  check not bf.isEmpty
  bf.excl 1
  check not bf.isEmpty
  bf.excl 55
  check bf.isEmpty

test "SHOULD be able to check the cardinality of the bitflags":
  var bf = Bitflags[64]()
  check bf.card == 0
  bf.incl 1
  check bf.card == 1
  bf.incl 55
  check bf.card == 2
  bf.excl 1
  check bf.card == 1
  bf.excl 55
  check bf.card == 0

test "SHOULD be able to access the fields of the bitflags":
  var bf = Bitflags[128]()
  bf.incl 0
  check bf[0] == 1
  check bf[1] == 0
  check bf[2] == 0
  check bf[3] == 0

  bf.incl 32 + 1
  check bf[0] == 1
  check bf[1] == 2
  check bf[2] == 0
  check bf[3] == 0

  bf.incl 64 + 2
  check bf[0] == 1
  check bf[1] == 2
  check bf[2] == 4
  check bf[3] == 0

  bf.incl 96 + 3
  check bf[0] == 1
  check bf[1] == 2
  check bf[2] == 4
  check bf[3] == 8

test "incl SHOULD raise an assertion error if the flag is out of bounds":
  var bf = Bitflags[64]()
  expect AssertionDefect:
    bf.incl 64
  expect AssertionDefect:
    bf.incl 100

test "excl SHOULD raise an assertion error if the flag is out of bounds":
  var bf = Bitflags[20]()
  expect AssertionDefect:
    bf.excl 32
  expect AssertionDefect:
    bf.excl 100

test "excl an empty Bitfields SHOULD NOT cause the cardinality to underflow":
  var bf = Bitflags[20]()
  check bf.card == 0
  bf.excl 5
  check bf.card == 0

test "incl a full Bitfields SHOULD NOT cause the cardinality to overflow":
  var bf = Bitflags[32]()
  for i in 0'u16 ..< 32:
    bf.incl i
  check bf.card == 32
  bf.incl 5
  check bf.card == 32
