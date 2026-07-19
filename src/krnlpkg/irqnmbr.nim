## Copyright 2026 Dean Hall See LICENSE for details
##
## KRNL: Interrupt number
##
## This module was created to eliminate a cyclic module depedency
##

import plat

type
  IrqNmbr* = 0'u8..uint8(plat.platIrqCnt - 1'u8) # interrupts are external to the ARM core
