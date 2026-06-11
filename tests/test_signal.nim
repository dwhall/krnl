# Copyright 2026 Dean Hall See LICENSE for details

import unittest2

# module under test:
include signal

test "SHOULD be able to create a signal":
  check compiles Sig("one", "two", "three", 42)

test "dotted signal source SHOULD be able to create a signal":
  check Sig("one.two.three", 42) is Signal

test "too many dots SHOULD not compile":
  check not compiles Sig("one.two.three.four", 64)

test "too few dots SHOULD not compile":
  check not compiles Sig("three.four", 64)

test "string case SHOULD NOT affect the signal value":
  check Sig("one.two.three", 42) == Sig("ONE.TWO.THREE", 42)

test "sig argument SHOULD affect the signal value":
  check Sig("one.two.three", 6) != Sig("one.two.three", 7)
