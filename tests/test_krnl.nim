## Copyright 2026 Dean Hall See LICENSE for details

import unittest2

# module under test:
import krnl

test "the Krnl type SHOULD exist":
  check true
  #check compiles:
  var k: Krnl
  k.init
