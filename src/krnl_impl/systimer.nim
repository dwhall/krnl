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
import proj
import ./[effects, event, krnl, signal]

const nsSysTimer = "tbd.krnl.systimer"

type
  SysTick* = uint64

  SysTimer* = object
    timers: HeapQueue[TimerInstance]
    platTimer: PlatTimerIntf

  TimerInstance = object
    nextCallTicks: SysTick
    intervalTicks: SysTick
    sig: Signal
    periodic: bool

  ## The platform timer handler passes the current tick count to the callback,
  ## and the callback returns the absolute tick count for the next callback.
  PrivilegedModeCallback* =
    proc(nowTicks: SysTick): SysTick {.tags: [PrivilegedModeEffect].}

  PlatTimerIntf* = object
    toTicks*: proc(millisecs: uint32, prescaler: uint32): SysTick
    stopTimer*: proc()
    startTimer*:
      proc(firstCallTicks: SysTick, callback: PrivilegedModeCallback, prescaler: uint32)
    getTicks*: proc(): SysTick

  TimerDeclarationList* = openArray[tuple[intervalMs: uint32, sigOrd: uint32]]

proc SigSysTimer*(sigOrd: static uint32): Signal {.compiletime.} =
  ## Returns a signal for the system timer with the given ordinal.
  Sig(nsSysTimer, sigOrd)

proc `<`(a, b: TimerInstance): bool =
  ## Imposes order in the heapqueue based on the next timer to expire
  a.nextCallTicks < b.nextCallTicks

proc mainSysTimer*(
    pSysTimer: ptr SysTimer,
    platTimer: sink PlatTimerIntf,
    timerDeclarationList: sink TimerDeclarationList,
    prescaler: uint32 = 0,
) =
  ## Initializes the system timer with the given platform timer interface.
  ## This MUST be called after switchToRamVectorTable().
  ## This MUST be called before any timers are created or used.
  var sysTimer: ptr SysTimer = pSysTimer # also used by timerCallback closure

  proc timerCallback(nowTicks: SysTick): SysTick {.tags: [PrivilegedModeEffect].} =
    ## This is the callback that is called by the platform timer when a timer expires.
    ## It publishes the signal of the expired timer and returns the next absolute tick count for the next timer to expire.
    # For each timer that has expired, publish its signal.
    # If the timer is periodic, reschedule it for its next expiration;
    # TODO: support margins for timer expiration (~5ms worth of ticks?)
    while sysTimer[].timers.len > 0 and sysTimer[].timers[0].nextCallTicks <= nowTicks:
      var expiredTimer = sysTimer[].timers.pop()
      # The event value carries the low 32 bits of the tick count
      let evnt =
        Event(sig: expiredTimer.sig, val: EventValue(nowTicks and 0xFFFF_FFFF'u64))
      publishEvent(evnt)
      if expiredTimer.periodic:
        inc expiredTimer.nextCallTicks, expiredTimer.intervalTicks
        sysTimer[].timers.push(expiredTimer)
    if sysTimer[].timers.len > 0:
      result = sysTimer[].timers[0].nextCallTicks
    else:
      result = 0.SysTick

  sysTimer[].platTimer = platTimer
  let now = platTimer.getTicks()
  for i, decl in timerDeclarationList.pairs:
    let
      intervalTicks = platTimer.toTicks(decl.intervalMs, prescaler)
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
