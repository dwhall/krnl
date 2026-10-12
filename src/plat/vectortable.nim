## Copyright 2026 Dean Hall See LICENSE for details
##
## KRNL: Vector Table definition for ARM Cortex-M device
##
## This module defines the RAM-based vector table used by KRNL.
## See docs/VectorTable.md for details.
##
## Reference:
##     https://developer.arm.com/documentation/ddi0403/latest
##     DDI0403E_e_armv7m_arm.pdf
##     B1.5 Armv7-M exception model
##

import plat

type
  ExnHandler = proc() {.noconv.}
  IrqHandler* = proc() {.noconv.}
  VectorTable* = object
    stackPointer {.align(vtorAlignment()).}: uint32
    exnHandler: array[1 .. 15, ExnHandler]
    irqHandler: array[IrqNmbr, IrqHandler]

  RamVectorTable* = VectorTable

func setIrqHandler*(self: var VectorTable, irqNmbr: IrqNmbr, handler: IrqHandler) =
  ## Sets the interrupt handler for the given interrupt number.
  self.irqHandler[irqNmbr] = handler

func findIrqHandler*(self: VectorTable, handler: IrqHandler): int =
  self.irqHandler.find(handler)
