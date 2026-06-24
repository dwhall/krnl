## Copyright 2026 Dean Hall See LICENSE for details
##
## System call interface and SVC dispatcher
##

import armv7m/core
import krnl, types

type
  SysCallId* = enum
    SysCallRegisterActor
    SysCallRegisterSignal

  SyscallArgs* = object
    case syscallId*: SysCallId
    of SysCallRegisterActor:
      actrAddr*: pointer
    of SysCallRegisterSignal:
      sig*: Signal

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

template syscall*(syscallArgs: ptr SyscallArgs) =
  ## Issues an SVC using R0 as a pointer to SyscallArgs.
  when defined(arm):
    asm """
      mov r0, %0
      svc #0
      :
      : "r"(`syscallArgs`)
      : "r0", "memory"
    """
  else:
    {.error: "syscall is only supported for ARM targets".}

proc syscallRegisterActor*(actrAddr: pointer) =
  ## Issues a syscall to register an actor
  let args = SyscallArgs(syscallId: SysCallRegisterActor, actrAddr: actrAddr)
  syscall(addr args)

proc syscallRegisterSignal*(sig: Signal) =
  ## Issues a syscall to register a signal
  let args = SyscallArgs(syscallId: SysCallRegisterSignal, sig: sig)
  syscall(addr args)

proc dispatchSyscall(pargs: ptr SyscallArgs) {.inline.} =
  if pargs == nil:
    return
  case pargs[].syscallId
  of SysCallRegisterActor:
    registerActor(pargs[].actrAddr)
  of SysCallRegisterSignal:
    registerSignal(pargs[].sig)

proc SVC_Handler*() {.exportc, noconv.} =
  ## Entry point referenced by the vector table and linker alias override.
  let frame = getStackedFramePtr(readLr())
  let pargs = cast[ptr SyscallArgs](frame.r0)
  dispatchSyscall(pargs)
