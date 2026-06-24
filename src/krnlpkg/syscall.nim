## Copyright 2026 Dean Hall See LICENSE for details
##
## KRNL: System call interface and SVC dispatcher
##

import armv7m/core
import krnl, types

type
  SyscallId* = enum
    SyscallInvalid
    SyscallRegisterActor
    SyscallRegisterSignal

  SyscallArgs* = object
    case syscallId*: SyscallId
    of SyscallInvalid:
      discard
    of SyscallRegisterActor:
      actrAddr*: pointer
    of SyscallRegisterSignal:
      sig*: Signal

  SyscallRetval* = object
    case syscallId*: SyscallId
    of SyscallInvalid:
      discard
    of SyscallRegisterActor:
      placeholderActor: uint32 # irqNmbr?
    of SyscallRegisterSignal:
      placeholderSignal: uint32 # sigHandle?

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

template syscall*(syscallArgs: ptr SyscallArgs): SyscallRetval =
  ## Issues an SVC with R0 = ptr to SyscallArgs, R1 = ptr to caller-owned
  ## SyscallRetval buffer. The syscall impl writes the result directly into result;
  ## no value is communicated back via R0.
  when defined(arm):
    let pRetval = addr result
    asm """
      mov r0, %0
      mov r1, %1
      svc #0
      :
      : "r"(`syscallArgs`), "r"(`pRetval`)
      : "r0", "r1", "memory"
    """
    result
  else:
    {.error: "syscall is only supported for ARM targets".}

proc syscallRegisterActor*(actrAddr: pointer): SyscallRetval =
  let args = SyscallArgs(syscallId: SyscallRegisterActor, actrAddr: actrAddr)
  syscall(addr args)

proc syscallRegisterSignal*(sig: Signal): SyscallRetval =
  let args = SyscallArgs(syscallId: SyscallRegisterSignal, sig: sig)
  syscall(addr args)

proc dispatchSyscall(pargs: ptr SyscallArgs): SyscallRetval {.inline.} =
  if pargs == nil:
    result.syscallId = SyscallInvalid
  else:
    result.syscallId = pargs[].syscallId
  case result.syscallId
  of SyscallRegisterActor:
    result.placeholderActor = registerActor(pargs[].actrAddr)
  of SyscallRegisterSignal:
    result.placeholderSignal = registerSignal(pargs[].sig)
  else:
    discard

proc SVC_Handler*() {.exportc, noconv.} =
  let frame = getStackedFramePtr(readLr())
  let pargs = cast[ptr SyscallArgs](frame.r0)
  let pretval = cast[ptr SyscallRetval](frame.r1)
  pretval[] = dispatchSyscall(pargs)
