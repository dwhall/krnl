## Copyright 2026 Dean Hall See LICENSE for details
##
## KRNL: System call interface and SVC dispatcher
##

import namespace, signal_registry

type
  SyscallId* = enum
    SyscallInvalid
    SyscallRegisterActr
    SyscallRegisterSignals

  SyscallArgs* = object
    case syscallId*: SyscallId
    of SyscallInvalid:
      discard
    of SyscallRegisterActr:
      actrAddr*: pointer
    of SyscallRegisterSignals:
      nsHash*: NamespaceHash
      maxSigEnum*: uint32

  SyscallRetval* = object
    case syscallId*: SyscallId
    of SyscallInvalid:
      discard
    of SyscallRegisterActr:
      discard
    of SyscallRegisterSignals:
      token*: SigPubToken

template syscall(syscallArgs: ptr SyscallArgs): SyscallRetval =
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

proc syscallRegisterActr*(actrAddr: pointer): SyscallRetval =
  let args = SyscallArgs(syscallId: SyscallRegisterActr, actrAddr: actrAddr)
  syscall(addr args)

proc syscallRegisterSignal*(dottedNames: static string, maxSigEnum: uint32): SyscallRetval =
  const nsHash = toNamespaceHash(dottedNames)
  let args = SyscallArgs(syscallId: SyscallRegisterSignals, nsHash: nsHash, maxSigEnum: maxSigEnum)
  syscall(addr args)
