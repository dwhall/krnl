## Copyright 2026 Dean Hall See LICENSE for details
##
## KRNL: Interrupt number
##
## This module was created to eliminate a cyclic module depedency
##

import plat

type IrqNmbr* = range[0 .. plat.platIrqCnt - 1] # interrupts are external to the ARM core
