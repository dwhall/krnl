## Copyright 2026 Dean Hall See LICENSE for details

## This module MUST NOT compile: copying an Actr is prohibited.
## `compiles` cannot detect a prohibited `=copy` (hooks are injected after
## semantic checking), so `nim test` compiles this file and expects failure.

# module under test:
include ../src/krnl_impl/actr # not krnl_intf/actr

proc copyActr() =
  var a: Actr
  a.initActr(3, 5.ActrPriority, nil)
  let b = a # a is read again below, so this is a copy, not a move
  discard a.priority
  discard b.priority

copyActr()
