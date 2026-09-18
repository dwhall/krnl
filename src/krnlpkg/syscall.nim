## Copyright 2026 Dean Hall See LICENSE for details
##
## KRNL: System call implementation and dispatcher
##

{.used.} # we import this module, but don't call any of its procs directly.

import armv7m/core
import krnl, syscall_intf

type StackedFrame = object
  r0, r1, r2, r3, r12, lr, pc, xpsr: uint32

proc dispatchSyscall(pargs: ptr SyscallArgs): SyscallResult {.inline.} =
  if pargs == nil:
    result.syscallId = SyscallInvalid
  else:
    result.syscallId = pargs.syscallId
    case result.syscallId
    of SyscallRegisterActr:
      registerActr(pargs.actrAddr)
    of SyscallRegisterSignals:
      result.token = registerSignals(pargs.nsHash, pargs.maxSig)
    else:
      discard

proc SVC_HandlerBody(frame: ptr StackedFrame) {.exportc, noconv.} =
  ## This handler implements the transition to privileged mode for syscalls.
  ## With this name, the linker places this handler in the nonvol vector table,
  ## which is then copied to the ram vector table at boot.
  let
    pargs = cast[ptr SyscallArgs](frame.r0)
    presult = cast[ptr SyscallResult](frame.r1)
  presult[] = dispatchSyscall(pargs)

proc SVC_Handler() {.exportc, noconv, asmNoStackFrame.} =
  asm """
    tst lr, #4       // EXC_RETURN bit 2: 0 = exception used MSP, 1 = used PSP
    ite eq
    mrseq r0, msp     // bit clear: pass main stack pointer to SVC_HandlerBody
    mrsne r0, psp     // bit set: pass process stack pointer to SVC_HandlerBody
    b SVC_HandlerBody // tail-call with r0 = ptr to stacked frame (StackedFrame*)
  """
