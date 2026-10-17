## Copyright 2026 Dean Hall See LICENSE for details
##
## KRNL: System call interface and SVC dispatcher
##

import plat, proj, vectortable # vectortable for IrqHandler
import actr, event, signal, signal_registry
import ../krnl_intf/namespace
type
  SyscallId* = enum
    SyscallInvalid
    SyscallRegisterActr
    SyscallRegisterSignals # SyscallEnableTimerEvent # How to catch the event (no name)?
    SyscallRegisterIrqHandler
    SyscallSubscribe
    SyscallPostEvent
    SyscallPublishEvent

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
    of SyscallSubscribe:
      actrAddr1*: ptr Actr
      sig*: Signal
    of SyscallPublishEvent:
      event*: Event
    of SyscallPostEvent:
      actrAddr2*: ptr Actr
      event1*: Event

  SyscallResult* = object
    case syscallId*: SyscallId
    of SyscallInvalid, SyscallRegisterActr, SyscallRegisterIrqHandler, SyscallSubscribe,
        SyscallPostEvent, SyscallPublishEvent:
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

proc syscallRegisterActr*(actrAddr: ptr Actr) =
  ## Issues a syscall to register an actor with the kernel
  let args = SyscallArgs(syscallId: SyscallRegisterActr, actrAddr: actrAddr)
  discard syscall(addr args)

proc syscallRegisterSignals*(dottedNames: static string, maxSig: uint32): SigPubToken =
  const nsHash = NS32(dottedNames)
  let args =
    SyscallArgs(syscallId: SyscallRegisterSignals, nsHash: nsHash, maxSig: maxSig)
  let scResult = syscall(addr args)
  scResult.token

proc syscallRegisterIrqHandler*(irqNmbr: IrqNmbr, irqHandler: IrqHandler) =
  let args = SyscallArgs(
    syscallId: SyscallRegisterIrqHandler, irqNmbr: irqNmbr, irqHandler: irqHandler
  )
  discard syscall(addr args)

proc syscallSubscribe*(actr: ptr Actr, sig: Signal) =
  let args = SyscallArgs(syscallId: SyscallSubscribe, actrAddr1: actr, sig: sig)
  discard syscall(addr args)

proc syscallPostEvent*(actr: ptr Actr, event: Event) =
  let args = SyscallArgs(syscallId: SyscallPostEvent, actrAddr2: actr, event1: event)
  discard syscall(addr args)

proc syscallPublishEvent*(event: Event) =
  let args = SyscallArgs(syscallId: SyscallPublishEvent, event: event)
  discard syscall(addr args)
