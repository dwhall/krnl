## Copyright 2026 Dean Hall See LICENSE for details
##
## BOOT: operations at and near processor start-up
##
#!fmt: off

import std/bitops
import armv7m/[fp, scb]
import nrf52840/device
import debug_rtt

const nvicPrioShift = cpu.nvicPriorityBits.uint32

proc validateNvicPriorityConfig() =
  ## Validates the NVIC's priority configuration
  ## and configures the core's floating-point unit

  # Determine the number of NVIC priority bits by writing all ones to the
  # NVIC IP register for PendSV and then reading back the result,
  # which has only the implemented bits set.
  let tmp = SCB.SHPR3.read().uint32 # store original value
  SCB.SHPR3.read()
           .PRI_14(0xFF) # write to PendSV prio
           .write()
  let prio = SCB.SHPR3.read().PRI_14.uint8 # read back implemented prio bits
  SCB.SHPR3.write(tmp) # restore original value
  # prio is an 8-bit field with the implemented bits set and packed toward the MSb.
  # nvicPrioShift is the offset to the least significant set bit of prio.
  let n = uint32(firstSetBit(prio) - 1)
  # If you reach this assert, either you used the wrong SVD file for your MCU
  # or the cpu/nvicPrioBits value in your SVD file is incorrect
  assert nvicPrioShift == n, "Calculated priority shift does not match declaration from SVD."

proc initFpu() =
  ## Initializes the floating-point unit if present
  when cpu.fpuAvail:  # Configure the floating-point unit
    FP.FPCCR.read()
            .ASPEN(1) # enable automatic FPU state preservation
            .LSPEN(1) # enable lazy stacking
            .write()

proc boot*() =
  ## Initializes the system after reset
  ## This is called after NimMain() and before main()
  initRTT()
  validateNvicPriorityConfig()
  initFpu()
