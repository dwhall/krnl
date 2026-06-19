## Copyright 2026 Dean Hall See LICENSE for details
##
## KRNL ActrSet type
##
## An ActrSet is a Bitflags where each bit corresponds to an actr's interrupt number.
## The quantity of interrupt numbers available depends on the platform/processor.
## The number of bits used in the Bitflags type must be determined at compile time.

import armv7m/nvic
import bitflags, plat

type ActrSet* = Bitflags[plat.platInterruptCount]

proc schedule*(actrset: ActrSet) =
  ## Schedules multiple actrs to activate by pending their interrupts in the NVIC
  ## In an ActrSet, the bit index corresponds to the actr's irqNmbr.
  ## The ActrSet set usually comes from the the subscribers to a signal.
  # NOTE: The caller MUST be in a critical section in privileged mode
  when true:
    when plat.platInterruptCount > 0:
      NVIC.NVIC_ISPR(0).write(actrset[0])
    when plat.platInterruptCount > 32:
      NVIC.NVIC_ISPR(1).write(actrset[1])
    when plat.platInterruptCount > 64:
      NVIC.NVIC_ISPR(2).write(actrset[2])
      NVIC.NVIC_ISPR(3).write(actrset[3])
    when plat.platInterruptCount > 128:
      NVIC.NVIC_ISPR(4).write(actrset[4])
      NVIC.NVIC_ISPR(5).write(actrset[5])
      NVIC.NVIC_ISPR(6).write(actrset[6])
      NVIC.NVIC_ISPR(7).write(actrset[7])
    # TODO: when plat.platInterruptCount > 256
  else:
    for idx, bundle in actrset.pairs:
      NVIC.NVIC_ISPR(idx).write(bundle)
