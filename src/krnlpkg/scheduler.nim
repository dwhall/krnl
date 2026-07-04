## Copyright 2026 Dean Hall See LICENSE for details
##
## Scheduler for KRNL
##
## KRNL employs the ArmV7M and ArmV8M cores' interrupt controller (NVIC)
## to schedule actrs.  Unused interrupts leave holes in the vector table.
## KRNL fills these holes with a procedure to dispatch an event
## to a specific actr's event handler.
## Scheduling an actr to run, then, is simply a matter of pending
## the appropriate interrupt.  This is done either by writing to STIR.INTID
## when only one actr is scheduled or by writing to multiple NVIC.NVIC_ISPR[]
## registers when multiple actrs are scheduled.
## The NVIC runs the highest priority pending interrupt and will tail-chain
## to the next highest priority pending interrupt when the current one finishes.
##

import std/math
import armv7m/[nvic, sig]
import bitflags, actr_set, vectortable

type Scheduler = object
  actrRegistry: array[plat.platInterruptCount, ref Actr]
  enabled: array[plat.platInterruptCount, bool]

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

# TODO: add the naked pragma
proc dispatchIrq[N: static InterruptNmbr]() =
  ## Dispatches the next event to the actr with irqNmbr N.
  ## ATTENTION: This procedure is called in the handler context
  ## This procedure's only use is to be placed in the vector table.
  const actr = getActr(N)
  schd.dispatch(N)
  let
    # FIXME: put these in the named registers
    R0 = actr.popEvent()
    LR = actr.stateHandler
    # TODO: return from interrupt
