## Copyright 2026 Dean Hall See LICENSE for details
##
## KRNL: System call implementation and SVC dispatcher
##

import armv7m/core
import krnl, types, namespace, signal_registry, syscall_intf

type
  StackedFrame = object
    r0: uint32
    r1: uint32
    r2: uint32
    r3: uint32
    r12: uint32
    lr: uint32
    pc: uint32
    xpsr: uint32

func readLr(): uint32 {.inline.} =
  asm """
    mov %0, lr
    : "=r"(`result`)
  """

func getStackedFramePtr(excReturn: uint32): ptr StackedFrame {.inline.} =
  ## EXC_RETURN bit[2]: 0 uses MSP, 1 uses PSP.
  if (excReturn and 0x4'u32) == 0'u32:
    cast[ptr StackedFrame](MSP.read().uint32)
  else:
    cast[ptr StackedFrame](PSP.read().uint32)

proc dispatchSyscall(pargs: ptr SyscallArgs): SyscallRetval {.inline.} =
  if pargs == nil:
    result.syscallId = SyscallInvalid
  else:
    result.syscallId = pargs[].syscallId
  case result.syscallId
  of SyscallRegisterActr:
    registerActr(pargs[].actrAddr)
  of SyscallRegisterSignals:
    result.token = registerSignals(pargs[].nsHash, pargs[].maxSigEnum)
  else:
    discard

proc SVC_Handler*() {.exportc, noconv.} =
  let frame = getStackedFramePtr(readLr())
  let pargs = cast[ptr SyscallArgs](frame.r0)
  let pretval = cast[ptr SyscallRetval](frame.r1)
  pretval[] = dispatchSyscall(pargs)
