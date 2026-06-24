## Copyright 2026 Dean Hall See LICENSE for details
##
## KRNL: System call interface and SVC dispatcher
##

import namespace, signal_registry, types

type
  SyscallId* = enum
    SyscallInvalid
    SyscallRegisterActor
    SyscallRegisterSignals
    # SyscallEnableTimerEvent # How to catch the event (no name)?

  SyscallArgs* = object
    case syscallId*: SyscallId
    of SyscallInvalid:
      discard
    of SyscallRegisterActor:
      actrAddr*: pointer
    of SyscallRegisterSignals:
      nsHash*: NamespaceHash
      maxSig*: uint32

  SyscallRetval* = object
    case syscallId*: SyscallId
    of SyscallInvalid:
      discard
    of SyscallRegisterActor:
      discard
    of SyscallRegisterSignals:
      discard

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

proc syscallRegisterActor*(actrAddr: pointer): SyscallRetval =
  ## Issues a syscall to register an actor with the kernel
  let args = SyscallArgs(syscallId: SyscallRegisterActor, actrAddr: actrAddr)
  syscall(addr args)

proc syscallRegisterSignals*(dottedNames: static string, maxSig: uint32): SyscallRetval =
  const nsHash = toNamespaceHash(dottedNames)
  let args = SyscallArgs(syscallId: SyscallRegisterSignals, nsHash: nsHash, maxSig: maxSig)
  syscall(addr args)

proc syscallPublishEvent*(event: Event) =
  ## Issues a syscall to publishes an event to all subscribers of the event's signal.
  discard
