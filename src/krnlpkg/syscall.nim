## Copyright 2026 Dean Hall See LICENSE for details
##
## KRNL: System call implementation and SVC dispatcher
##

import armv7m/core
import krnl, syscall_intf

type StackedFrame = object
  r0: uint32
  r1: uint32
  r2: uint32
  r3: uint32
  r12: uint32
  lr: uint32
  pc: uint32
  xpsr: uint32

proc dispatchSyscall(pargs: ptr SyscallArgs): SyscallRetval {.inline.} =
  if pargs == nil:
    result.syscallId = SyscallInvalid
  else:
    result.syscallId = pargs[].syscallId
  case result.syscallId
  of SyscallRegisterActor:
    registerActor(pargs[].actrAddr)
  of SyscallRegisterSignals:
    registerSignals(pargs[].nsHash, pargs[].maxSig)
  else:
    discard

proc SVC_Handler*() {.exportc, noconv.} =
  let mainStackPtr = cast[ptr StackedFrame](MSP.read().uint32)
  let pargs = cast[ptr SyscallArgs](mainStackPtr.r0)
  let pretval = cast[ptr SyscallRetval](mainStackPtr.r1)
  pretval[] = dispatchSyscall(pargs)
