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

{.compile: "vector_table.c".}

import armv7m/core
import irqnmbr, plat

type
  ExnNmbr = 1 .. (16 + plat.platIrqCnt)
    # exceptions include those internal to the ARM core
    # and external interrupts
  ExnHandler = proc()
  IrqHandler = proc()
  VectorTable* = object
    stackPointer: uint32
    exnHandler: array[1 .. 16, ExnHandler]
    irqHandler: array[IrqNmbr, IrqHandler]

const invalidIrqNmbr* = IrqNmbr(0)

proc default_Handler() {.exportc, noconv.} =
  while true:
    when defined(arm):
      WFI()
    else:
      discard

# The non-volatile Vector Table used at power-on-reset; from vector_table.c
let c_vectorTable* {.importc: "c_vectorTable", used.}: VectorTable

converter toInterruptNumber*(exnNmbr: ExnNmbr): IrqNmbr =
  ## Converts an exception number to an interrupt number
  assert exnNmbr.int >= 16, "Exceptions lower than 16 are not interrupts"
  IrqNmbr(exnNmbr.int - 16)

proc unusedIsr() =
  ## This procedure is used to fill unused slots in the vector table.
  ## It should never be called.  It is used by this module for the logic
  ## to know which slots are unused
  while true:
    discard

proc initVectorTable*(self: var VectorTable) =
  self.stackPointer = c_vectorTable.stackPointer
  self.exnHandler = c_vectorTable.exnHandler
  for handler in self.irqHandler.mitems:
    handler = unusedIsr

func setIrqHandler*(self: var VectorTable, irqNmbr: IrqNmbr, handler: IrqHandler) =
  ## Sets the interrupt handler for the given interrupt number.
  self.irqHandler[irqNmbr] = handler

# TODO: enforce that this may only be called AFTER the vector table
# is populated with the irq handlers
func getUnusedIrqNmbr*(self: VectorTable): IrqNmbr =
  ## Returns the first unused interrupt slot index in the vector table
  ## or invalidIrqNmbr if no slots are unused.
  for idx, handler in self.irqHandler.pairs:
    if handler == unusedIsr:
      return IrqNmbr(idx)
  return invalidIrqNmbr
