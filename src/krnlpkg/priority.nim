## Copyright 2026 Dean Hall See LICENSE for details
##

import armv7m/[core, nvic]
import irqnmbr, math, plat

type
  ActrPriority* = 0 .. (0xFF shr plat.platNvicPriorityBits) # 0 is the lowest priority
  NvicPriority = uint8 # 0 is the highest priority

converter toNvicPriority*(prio: ActrPriority): NvicPriority =
  ## Converts ActrPriority where 0 is the lowest priority
  ## to NvicPriority where 0 is the highest priority
  NvicPriority(
    ((0xFF'u32 shr plat.platNvicPriorityBits) + 1'u32 - prio.uint32) shl
      plat.platNvicPriorityBits
  )

template CRIT_ENTER() =
  disableIrq()

template CRIT_EXIT() =
  enableIrq()

proc setPriority*(irqNmbr: static IrqNmbr, prio: ActrPriority) =
  ## Sets the this actr's interrupt's priority
  ## and enables the interrupt in the NVIC
  const
    (irqDiv4, irqMod4) = divmod(irqNmbr, 4'u8)
    iprReg = NVIC.NVIC_IPR(irqDiv4)

    (irqDiv32, irqMod32) = divmod(irqNmbr, 32'u8)
    iserReg = NVIC.NVIC_ISER(irqDiv32)

    irqBitf = 1'u32 shl irqMod32
    nvicPrio: NvicPriority = prio # implicitly calls the converter

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
  # TODO: clear any pending interrupt
  # Enable the interrupt associated with this Actr
  iserReg = irqBitf
  CRIT_EXIT()
