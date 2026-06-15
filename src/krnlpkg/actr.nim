## Copyright 2026 Dean Hall See LICENSE for details
##
## KRNL Actr operations
##

import math
import armv7m/[core, nvic, sig]
import plat, types

template CRIT_ENTER() =
  disableIrq()

template CRIT_EXIT() =
  enableIrq()

template schedule(self: Actr) =
  ## Schedules the actr for execution by pending its interrupt in the NVIC
  # NOTE: The caller MUST be in a critical section in privileged mode
  SIG.STIR.INTID(self.irqNmbr)

proc activate*(self: var Actr) =
  ## Pops an event within a critical section and calls the actr's event handler.
  ## If the actr's event queue is not empty after popping,
  ## the actr is scheduled for execution again.
  # NOTE: MUST only be called when the actr has an event in its queue
  # NOTE: The caller MUST be in privileged mode
  assert self.eventQue.len() > 0'u8
  CRIT_ENTER()
  let e = self.eventQue.pop()
  if self.eventQue.len() > 0:
    self.schedule()
  CRIT_EXIT()
  self.dispatch(e) # actr's event handler

func post*(self: var Actr, e: Event) =
  ## Posts an event to the actr and schedules the actr for execution
  ## within a critical section
  # NOTE: The caller MUST be in privileged mode
  CRIT_ENTER()
  self.eventQue.add(e)
  self.schedule()
  CRIT_EXIT()

proc setPriority*(self: var Actr, prio: ActrPriority) =
  ## Sets the this actr's interrupt's priority
  ## and enables the interrupt in the NVIC
  assert self.irqNmbr > 0'u8
  assert prio <= (0xFF'u8 shr plat.platNvicPriorityBits)

  let (irqDiv4, irqMod4) = divmod(self.irqNmbr, 4'u8)
  let iprReg = NVIC.NVIC_IPR(irqDiv4)

  let (irqDiv32, irqMod32) = divmod(self.irqNmbr, 32'u8)
  let irqBitf = 1'u32 shl irqMod32
  let iserReg = NVIC.NVIC_ISER(irqDiv32)

  let nvicPrio: NvicPriority = prio # implicitly calls the converter
  CRIT_ENTER()
  # Set the priority of the interrupt associated with this Actr
  case irqMod4
  of 0:
    iprReg.PRI_N0(nvicPrio).write()
  of 1:
    iprReg.PRI_N1(nvicPrio).write()
  of 2:
    iprReg.PRI_N2(nvicPrio).write()
  of 3:
    iprReg.PRI_N3(nvicPrio).write()
  # Enable the interrupt associated with this Actr
  iserReg = irqBitf
  CRIT_EXIT()

func setIrq*(self: var Actr, irq: uint8) =
  self.irqNum = irq
