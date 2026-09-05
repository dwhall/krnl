## Copyright 2026 Dean Hall See LICENSE for details
##
## BOOT: operations at and near processor start-up
##

import std/bitops
import armv7m/[fp, scb]
import debug_rtt, plat

proc validateNvicPriorityConfig() {.inline.} =
  ## Validates the NVIC's priority configuration
  ## and configures the core's floating-point unit

  # Determine the number of NVIC priority bits by writing all ones to the
  # NVIC IP register for PendSV and then reading back the result,
  # which has only the implemented bits set.
  let originalValue = SCB.SHPR3.read().uint32
  SCB.SHPR3.read().PRI_14(0xFF).write()
  let prio = SCB.SHPR3.read().PRI_14.uint8 # read back implemented prio bits
  SCB.SHPR3.write(originalValue)
  # prio is an 8-bit field with the implemented bits set and packed toward the MSb.
  # nvicPrioBits is the offset to the least significant set bit of prio.
  let n = firstSetBit(prio) - 1
  # If you reach this assert, either you used the wrong SVD file for your MCU
  # or the cpu/nvicPrioBits value in your SVD file is incorrect
  assert plat.nvicPriorityBits() == n,
    "Calculated priority bits does not match the declared platform value."

proc initFpu(
    enableAutoStatePreserve: static uint32 = 1, enableLazyStacking: static uint32 = 1
) {.inline.} =
  ## Initializes the floating-point unit if present
  when plat.fpuAvail():
    FP.FPCCR.read().ASPEN(enableAutoStatePreserve).LSPEN(enableLazyStacking).write()

proc setNvicPriorityGrouping(grouping: static uint32 = 0) {.inline.} =
  const writeKey = 0x05FA
  SCB.AIRCR.read().VECTKEY(writeKey).PRIGROUP(grouping).write()

proc boot*() =
  ## Initializes the system after reset
  ## This is called after NimMain() and before main()
  initRTT()
  validateNvicPriorityConfig()
  initFpu()
  setNvicPriorityGrouping()
