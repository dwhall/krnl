## Copyright 2026 Dean Hall See LICENSE for details
##
## KRNL: System call interface and SVC dispatcher
##

import plat
import actr, krnl, namespace, signal_registry
import vectortable # for IrqHandler

type
  SyscallId* = enum
    SyscallInvalid
    SyscallRegisterActr
    SyscallRegisterSignals # SyscallEnableTimerEvent # How to catch the event (no name)?
    SyscallRegisterIrqHandler

  SyscallArgs* = object
    case syscallId*: SyscallId
    of SyscallInvalid:
      discard
    of SyscallRegisterActr:
      actrAddr*: ptr Actr
    of SyscallRegisterSignals:
      nsHash*: NamespaceHash32
      maxSig*: uint32
    of SyscallRegisterIrqHandler:
      irqNmbr*: IrqNmbr
      irqHandler*: IrqHandler

  SyscallResult* = object
    case syscallId*: SyscallId
    of SyscallInvalid, SyscallRegisterActr, SyscallRegisterIrqHandler:
      discard
    of SyscallRegisterSignals:
      token*: SigPubToken

proc syscall(syscallArgs: ptr SyscallArgs): SyscallResult {.inline.} =
  ## Issues an SVC with R0 = ptr to SyscallArgs, R1 = ptr to result.
  ## The syscall impl writes the result directly into result;
  ## no value is communicated back via R0.
  when defined(arm):
    let pResult = addr result
    asm """
      mov r0, %0
      mov r1, %1
      svc #0
      :
      : "r"(`syscallArgs`), "r"(`pResult`)
      : "r0", "r1", "memory"
    """
    result
  else:
    {.error: "syscall is only supported for ARM targets".}

proc syscallRegisterActr*(actrAddr: ptr Actr): SyscallResult =
  ## Issues a syscall to register an actor with the kernel
  let args = SyscallArgs(syscallId: SyscallRegisterActr, actrAddr: actrAddr)
  syscall(addr args)

proc syscallRegisterSignals*(
    dottedNames: static string, maxSig: uint32
): SyscallResult =
  const nsHash = NS32(dottedNames)
  let args =
    SyscallArgs(syscallId: SyscallRegisterSignals, nsHash: nsHash, maxSig: maxSig)
  syscall(addr args)

proc syscallRegisterIrqHandler*(
    irqNmbr: IrqNmbr, irqHandler: IrqHandler
): SyscallResult =
  let args = SyscallArgs(
    syscallId: SyscallRegisterIrqHandler, irqNmbr: irqNmbr, irqHandler: irqHandler
  )
  syscall(addr args)
