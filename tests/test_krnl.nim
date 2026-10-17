## Copyright 2026 Dean Hall See LICENSE for details

import unittest2

# module under test:
import krnl

test "the Krnl type SHOULD exist":
  check declared Krnl

test "initKrnl SHOULD accept a ptr Krnl":
  # Compile-only: initKrnl writes core registers and reads the
  # linker-provided c_vectorTable, so it cannot run on the host
  var k: Krnl
  check compiles initKrnl(addr k)
