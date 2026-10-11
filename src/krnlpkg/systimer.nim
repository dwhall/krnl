## Copyright 2026 Dean Hall See LICENSE for details
##
## KRNL system timers
##
## A system timer is a timer that emits an Event when it expires.  There are two
## kinds of system timers: project and private.  Project timers are declared in
## the project and are published to all subscribed Actrs.  Project timers do
## not start being published until after system init is complete.  Private
## timers are declared by a single Actr and are posted only to that Actr.
## Private timers may be one-shot or periodic.
##

import std/heapqueue
import krnlpkg/[effects, event, signal]

const nsSysTimer* = "tbd.krnl.systimer"

type
  SysTimer* = object
    timers: HeapQueue[TimerInstance]
    platTimer: PlatTimerIntf
    publishEvent: PublishEventProc

  TimerInstance = object
    nextCallTicks: uint32
    intervalTicks: uint32
    sig: Signal
    periodic: bool

  ## The platform timer handler passes the current tick count to the callback,
  ## and the callback returns the absolute tick count for the next callback.
  PrivilegedModeCallback* =
    proc(nowTicks: uint32): uint32 {.nimcall, tags: [PrivilegedModeEffect].}

  ## The kernel's publishEvent, injected at init so this module need not import
  ## krnl (which would be circular).  It is called directly from the timer ISR,
  ## which already runs privileged, so no syscall is needed (or allowed).
  # TODO: Nim 2.4.0 may have {.cyclic.} pragma to tolerate import krnl
  PublishEventProc* = proc(evnt: Event) {.nimcall, tags: [PrivilegedModeEffect].}

  PlatTimerIntf* = object
    toTicks*: proc(millisecs: uint32, prescaler: uint32): uint32
    stopTimer*: proc()
    startTimer*:
      proc(firstCallTicks: uint32, callback: PrivilegedModeCallback, prescaler: uint32)
    getTicks*: proc(): uint32

  TimerDeclaration* = object
    intervalMs: uint32
    sigOrd: uint32

var sysTimer: ptr SysTimer

proc SigSysTimer*(sigOrd: static uint32): Signal {.compiletime.} =
  ## Returns a signal for the system timer with the given ordinal.
  Sig(nsSysTimer, sigOrd)

proc `<`(a, b: TimerInstance): bool =
  ## Imposes order in the heapqueue based on the next timer to expire
  a.nextCallTicks < b.nextCallTicks

proc timerCallback(nowTicks: uint32): uint32 {.nimcall, tags: [PrivilegedModeEffect].} =
  ## This is the callback that is called by the platform timer when a timer expires.
  ## It publishes the signal of the expired timer and returns the next absolute tick count for the next timer to expire.
  # For each timer that has expired, publish its signal.
  # If the timer is periodic, reschedule it for its next expiration;
  # TODO: support margins for timer expiration (~5ms worth of ticks?)
  while sysTimer[].timers.len > 0 and sysTimer[].timers[0].nextCallTicks <= nowTicks:
    var expiredTimer = sysTimer[].timers.pop()
    let evnt = Event(sig: expiredTimer.sig, val: nowTicks)
    sysTimer[].publishEvent(evnt)
    if expiredTimer.periodic:
      inc expiredTimer.nextCallTicks, expiredTimer.intervalTicks
      sysTimer[].timers.push(expiredTimer)
  if sysTimer[].timers.len > 0:
    result = sysTimer[].timers[0].nextCallTicks
  else:
    result = 0'u32

proc mainSysTimer*(
    pSysTimer: ptr SysTimer,
    plat: PlatTimerIntf,
    publishEvent: PublishEventProc,
    timerDeclarations: openArray[tuple[intervalMs: uint32, sigOrd: uint32]],
    prescaler: uint32 = 0,
) =
  ## Initializes the system timer with the given platform timer interface.
  ## This must be called before any timers are created or used.
  sysTimer = pSysTimer
  sysTimer[].platTimer = plat
  sysTimer[].publishEvent = publishEvent
  let now = plat.getTicks()
  for i, decl in timerDeclarations.pairs:
    let
      intervalTicks = plat.toTicks(decl.intervalMs, prescaler)
      firstCallTicks = now + intervalTicks
      sig = Sig(nsSysTimer, decl.sigOrd)
      timer = TimerInstance(
        nextCallTicks: firstCallTicks,
        intervalTicks: intervalTicks,
        sig: sig,
        periodic: true,
      )
    sysTimer[].timers.push(timer)
  # The heap's 0th element is the next timer to expire
  let firstCallTicks = sysTimer[].timers[0].nextCallTicks
  sysTimer[].platTimer.startTimer(firstCallTicks, timerCallback, prescaler)
