## Copyright 2026 Dean Hall See LICENSE for details
##
## Scheduler for KRNL
##
## KRNL employs the ArmV7M and ArmV8M cores' interrupt controller (NVIC)
## to schedule actrs.  Unused interrupts leave holes in the vector table.
## KRNL fills these holes with a procedure to dispatch an event
## to a specific actr's event handler.
## Scheduling an actr to run, then, is simply a matter of triggering
## the appropriate interrupt.  This is done either by writing to STIR.INTID
## when only one actr is scheduled or by writing to multiple NVIC.NVIC_ISPR[]
## registers when multiple actrs are scheduled.
## The NVIC runs the highest priority pending interrupt and will tail-chain
## to the next highest priority pending interrupt when the current one finishes.
##

import std/math
import armv7m/[nvic, sig]
import nrf52840/device
import bitflags, actr_set, types

const PLAT_IRQ_CNT = 256 # placeholder; shold come from device import

type Scheduler = object
  actrRegistry: array[PLAT_IRQ_CNT, ref Actr]
  enabled: array[PLAT_IRQ_CNT, bool]

proc registerActr(schd: var Scheduler, actr: ref Actr) =
  ## Registers a actr with this kernel
  schd.actrRegistry[actr.irqNmbr] = actr
  # TODO: register the actr's public emitted signals with the signal registry

proc getActr(schd: Scheduler, irqNmbr: static InterruptNmbr): ref Actr =
  ## Returns the actr associated with the given interrupt number.
  schd.actrRegistry[irqNmbr]

proc enable(schd: var Scheduler, actr: ref Actr) =
  ## Enable a actr's interrupt so it can be scheduled
  let (regIdx, bitIdx) = actr.irqNmbr.divmod 32
  schd.enabled[actr.irqNmbr] = true
  NVIC.NVIC_ISER(regIdx).SETENA(bitIdx, 1)

proc disable(schd: var Scheduler, actr: ref Actr) =
  ## Disable the actr's interrupt so it won't be scheduled
  let (regIdx, bitIdx) = actr.irqNmbr.divmod 32
  schd.enabled[actr.irqNmbr] = false
  NVIC.NVIC_ICER(regIdx).SETENA(bitIdx, 1)

proc schedule(schd: Scheduler, actr: ref Actr) =
  ## Schedule a single actr to run by pending its interrupt
  SIG.STIR.INTID(actr.irqNmbr)

proc schedule(schd: Scheduler, actrset: ActrSet) =
  ## Schedule multiple actrs to run by pending their interrupts.
  ## In an ActrSet, the bit index corresponds to the actr's irqNmbr.
  ## The ActrSet set usually comes from the the subscribers to a signal.
  when true:
    when PLAT_IRQ_CNT > 0:
      NVIC.NVIC_ISPR[0] = actrset[0]
    when PLAT_IRQ_CNT > 32:
      NVIC.NVIC_ISPR[1] = actrset[1]
    when PLAT_IRQ_CNT > 64:
      NVIC.NVIC_ISPR[2] = actrset[2]
      NVIC.NVIC_ISPR[3] = actrset[3]
    when PLAT_IRQ_CNT > 128:
      NVIC.NVIC_ISPR[4] = actrset[4]
      NVIC.NVIC_ISPR[5] = actrset[5]
      NVIC.NVIC_ISPR[6] = actrset[6]
      NVIC.NVIC_ISPR[7] = actrset[7]
    # TODO: when PLAT_IRQ_CNT > 256
  else:
    for idx, bundle in actrset.pairs:
      NVIC.NVIC_ISPR[idx] = bundle

# TODO: add the naked pragma
proc dispatch(schd: Scheduler, irqNmbr: static InterruptNmbr) =
  ## Dispatches the next event to the actr with the given irqNmbr.
  ## ATTENTION: This procedure is called in the handler context
  const actr = schd.getActr(irqNmbr)
  let
    # FIXME: put these in the named registers
    R0 = actr.popEvent()
    LR = actr.stateHandler
    # TODO: return from interrupt

# Example:
proc dispatchIrq17(schd: Scheduler) =
  ## Declares a dispatch procedure for the actr with irqNmbr 17.
  ## This procedure's only use is to be placed in the vector table.
  schd.dispatch(17)
