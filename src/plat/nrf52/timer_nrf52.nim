## Copyright 2025 Dean Hall, see LICENSE for details
##
## KRNL platform timer
##
## Provides the hardware-specific timer implementation for KRNL's systimer.
## Provides a callback at a given absolute tick count.  The callback,
## systimer, returns the next absolute tick count to be called at.
##

import armv7m/nvic
import nrf52840/rtc
import ../../krnl_impl/systimer
import ../../krnl_intf/[effects, syscall]

const
  rtc1CounterBits = 24 # RTC COUNTER register width
  rtc1CounterMask = (1'u64 shl rtc1CounterBits) - 1

var
  rtc1Prescaler: uint32
  rtc1Callback: PrivilegedModeCallback
  rtc1Overflows {.volatile.}: uint32
    ## Count of COUNTER overflows; forms the upper bits of the tick count.
    ## Kept at 32 bits so thread-mode reads of it are atomic.

func toTicks(millisecs: uint32, prescaler: uint32): SysTick =
  ## Converts milliseconds to hardware ticks, given the current prescaler.
  # TODO: involve the prescaler
  SysTick(millisecs * 32768'u32 div 1000'u32)

proc getTicks(): SysTick =
  ## Returns the current tick count, extended to 64 bits by the overflow count.
  ## Safe to call from thread mode or from the RTC1 ISR.
  while true:
    let overflows = rtc1Overflows
    var hi = overflows
    var lo = RTC1.COUNTER.read().COUNTER().uint32
    if RTC1.EVENTS_OVRFLW.read().uint32 != 0:
      # COUNTER wrapped but the ISR hasn't counted it yet.
      # Re-read COUNTER so lo is certainly from after the wrap.
      lo = RTC1.COUNTER.read().COUNTER().uint32
      inc hi
    # If the ISR counted an overflow while we were reading, try again
    if rtc1Overflows == overflows:
      return (hi.SysTick shl rtc1CounterBits) or lo.SysTick

proc stopTimer() =
  ## Stops the hardware timer, clear pending interrupt
  RTC1.TASKS_STOP.TASKS_STOP(1)
  RTC1.TASKS_CLEAR.TASKS_CLEAR(1)
  RTC1.EVENTS_OVRFLW.write(0)
  rtc1Overflows = 0
  NVIC.NVIC_ICPR(0).CLRPEND(irq_RTC1, 1)

proc RTC1IrqHandler() {.noconv, tags: [PrivilegedModeEffect].} =
  if RTC1.EVENTS_OVRFLW.read().uint32 != 0:
    RTC1.EVENTS_OVRFLW.write(0)
    inc rtc1Overflows
  if RTC1.EVENTS_COMPARE(0).read().uint32 != 0:
    RTC1.EVENTS_COMPARE(0).write(0)
    # FOUR clock cycles must happen after the above write
    # and before the proc returns
    # per nRF52840_PS_v1.11.pdf p.175
    if rtc1Callback == nil:
      # TODO: disable the interrupt
      return
    let nowTicks = getTicks()
    let nextCompare = rtc1Callback(nowTicks)
    # CC holds only the lower 24 bits.  A compare more than one COUNTER
    # period away fires early; the callback finds nothing due and returns
    # the same compare value, so it is simply re-armed.
    RTC1.CC(0).COMPARE((nextCompare and rtc1CounterMask).uint32)
    NVIC.NVIC_ICPR(0).CLRPEND(irq_RTC1, 1)

proc startTimer(
    firstCallTicks: SysTick, callback: PrivilegedModeCallback, prescaler: uint32 = 0'u32
) =
  ## Starts the hardware timer
  stopTimer()
  RTC1.PRESCALER.PRESCALER(prescaler)
  RTC1.CC(0).COMPARE((firstCallTicks and rtc1CounterMask).uint32)
  RTC1.INTENSET.COMPARE0(1)
  RTC1.INTENSET.OVRFLW(1)
  discard syscallRegisterIrqHandler(irq_RTC1, RTC1IrqHandler)
  RTC1.TASKS_START.TASKS_START(1)
  rtc1Callback = callback
  rtc1Prescaler = prescaler

const rtc1Timer* = PlatTimerIntf(
  toTicks: toTicks, stopTimer: stopTimer, startTimer: startTimer, getTicks: getTicks
)
