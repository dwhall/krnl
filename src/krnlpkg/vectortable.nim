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

import irqnmbr, krnl, plat

type
  ExnNmbr = 1..(16 + plat.platIrqCnt)
    # exceptions include those internal to the ARM core
    # and external interrupts
  ExnHandler = proc()
  IrqHandler = proc()
  VectorTable = object
    stackPointer: uint32
    exnHandler: array[1 .. 16, ExnHandler]
    irqHandler: array[IrqNmbr, IrqHandler]

const invalidIrqNmbr* = IrqNmbr(0)

# The non-volatile Vector Table used at power-on-reset; from vector_table.c
let c_vectorTable {.importc: "vectorTable".}: VectorTable

converter toInterruptNumber*(exnNmbr: ExnNmbr): IrqNmbr =
  ## Converts an exception number to an interrupt number
  assert exnNmbr.int >= 16, "Exceptions lower than 16 are not interrupts"
  IrqNmbr(exnNmbr.int - 16)

func unusedIsr() =
  ## This procedure is used to fill unused slots in the vector table.
  ## It should never be called.  It is used by this module for the logic
  ## to know which slots are unused
  while true:
    discard

func initVectorTable(self: var VectorTable, prevVt: VectorTable) =
  self.stackPointer = prevVt.stackPointer
  self.exnHandler = prevVt.exnHandler
  for i in 0 ..< plat.platIrqCnt:
    self.irqHandler[i] = unusedIsr

func setIrqHandler*(self: var VectorTable, irqNmbr: IrqNmbr, handler: IrqHandler) =
  ## Sets the interrupt handler for the given interrupt number.
  self.irqHandler[irqNmbr.int] = handler

# TODO: enforce that this MUST be called AFTER the vector table
# is populated with the irq handlers
func getUnusedIrqNmbr*(self: VectorTable): IrqNmbr =
  ## Returns the first unused interrupt slot in the vector table.
  for i in 0 ..< plat.platIrqCnt:
    if self.irqHandler[i] == unusedIsr:
      return IrqNmbr(i)
  return invalidIrqNmbr

proc dispatchIsr*[N: static IrqNmbr]() {.asmNoStackFrame.} =
  ## Dispatches the actr's next event to the actr with irqNmbr N.
  ## ATTENTION: This procedure is called in the handler context
  ## This procedure's only use is to be placed in the vector table.
  #[
    B1.5.8 Exception return behavior
    An exception return occurs when the processor is in Handler mode and
    one of the following instructions loads a value of 0xFXXXXXXX into the PC:
    * POP/LDM that includes loading the PC.
    * LDR with PC as a destination.
    * BX with any register.
  ]#
  let
    actr = getActr(N)
    evnt = actr.popEvent()
    handler = actr.eventHandler
  asm """
    mov r0, %0
    mov lr, %1
    ldr pc, #0xF0000000 ; return from exception
    :
    : "r"(`evnt`), "r"(`handler`)
    : "r0", "r1", "memory"
  """
