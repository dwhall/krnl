## Copyright 2026 Dean Hall See LICENSE for details

import unittest2

# module under test:
include bitfield

test "SHOULD be able to create a bitfield":
  check compiles Bitfield[32]()

test "cap SHOULD return the capacity of the bitfield":
  let bf1 = Bitfield[64]()
  check bf1.cap == 64
  let bf2 = Bitfield[88]()
  check bf2.cap == 96

test "SHOULD be able to include a flag in the bitfield":
  var bf = Bitfield[32]()
  check compiles bf.incl 5

test "SHOULD be able to check if a flag is in the bitfield":
  var bf = Bitfield[64]()
  bf.incl 55
  check 55 in bf

test "SHOULD be able to check if a flag is not in the bitfield":
  var bf = Bitfield[64]()
  bf.incl 55
  check 23 notin bf

test "SHOULD be able to exclude a flag from the bitfield":
  var bf = Bitfield[64]()
  check compiles bf.excl 55

test "SHOULD be able to check that a flag is excluded":
  var bf = Bitfield[64]()
  bf.incl 55
  bf.incl 0
  bf.excl 55
  check 55 notin bf

test "SHOULD be able to check that a flag is not excluded":
  var bf = Bitfield[64]()
  bf.incl 55
  bf.incl 0
  bf.excl 55
  check 0 in bf

test "SHOULD be able to check if the bitfield is empty":
  var bf = Bitfield[64]()
  check bf.isEmpty
  bf.incl 1
  check not bf.isEmpty
  bf.incl 55
  check not bf.isEmpty
  bf.excl 1
  check not bf.isEmpty
  bf.excl 55
  check bf.isEmpty

test "SHOULD be able to check the cardinality of the bitfield":
  var bf = Bitfield[64]()
  check bf.card == 0
  bf.incl 1
  check bf.card == 1
  bf.incl 55
  check bf.card == 2
  bf.excl 1
  check bf.card == 1
  bf.excl 55
  check bf.card == 0

test "SHOULD be able to access the fields of the bitfield":
  var bf = Bitfield[128]()
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
