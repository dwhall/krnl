## Copyright 2026 Dean Hall See LICENSE for details
##
## KRNL ActrSet type
##
## An ActrSet is a Bitflags where each bit corresponds to an actr's interrupt number.
## The quantity of interrupt numbers available depends on the platform/processor.
## The number of bits used in the Bitflags type must be determined at compile time
## so that the storage may be declared statically.
##

import armv7m/nvic
import bitflags, effects, plat

type ActrSet* = Bitflags[plat.irqCnt()]

proc excl*(self: var ActrSet, irqNmbr: IrqNmbr) =
  ## Removes the actr with `irqNmbr` from the set.
  self.excl(irqNmbr.int)

proc incl*(self: var ActrSet, irqNmbr: IrqNmbr) =
  ## Adds the actr with `irqNmbr` to the set.
  self.incl(irqNmbr.int)

proc contains*(self: ActrSet, irqNmbr: IrqNmbr): bool =
  self.contains(irqNmbr)

proc schedule*(actrset: ActrSet) {.tags: [PrivilegedModeEffect].} =
  ## Schedules multiple actrs to activate by pending their interrupts in the NVIC
  ## In an ActrSet, the bit index corresponds to the actr's irqNmbr.
  ## The ActrSet set usually comes from the the subscribers to a signal.
  ## NOTE: The caller MUST be in a critical section in privileged mode
  when plat.irqCnt() > 128:
    for idx, bundle in actrset.pairs:
      NVIC.NVIC_ISPR(idx).write(bundle)
  else:
    when plat.irqCnt() > 0:
      NVIC.NVIC_ISPR(0).write(actrset[0])
    when plat.irqCnt() > 32:
      NVIC.NVIC_ISPR(1).write(actrset[1])
    when plat.irqCnt() > 64:
      NVIC.NVIC_ISPR(2).write(actrset[2])
      NVIC.NVIC_ISPR(3).write(actrset[3])
