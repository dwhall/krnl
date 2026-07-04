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
  ExceptionNmbr* = 1 .. 16 + plat.platInterruptCount # ARM Exception number
  InterruptNmbr* = 0 .. plat.platInterruptCount - 1 # ARM Interrupt number

  ExceptionHandler = proc()
  InterruptHandler = proc()
  VectorTable[N: static uint] = object
    stackPointer: uint32
    exceptionHandler: array[1 .. 16, ExceptionHandler]
    interruptHandler: array[N, InterruptHandler]

# The RAM-based Vector Table
var vt: VectorTable[plat.platInterruptCount]

# The Flash-based Vector Table
let c_vectorTable {.importc: "vectorTable".}: VectorTable[plat.platInterruptCount]

converter toInterruptNumber*(exnNmbr: ExceptionNmbr): InterruptNmbr =
  ## Converts an exception number to an interrupt number
  assert exnNmbr.int >= 16, "Exceptions lower than 16 are not interrupts"
  InterruptNmbr(exnNmbr.int - 16)

func unusedSlot() =
  ## This procedure is used to fill unused slots in the vector table.
  ## It should never be called.  It is used by this module for the logic
  ## to know which slots are unused
  while true:
    discard

proc initVectorTable() =
  vt.stackPointer = c_vectorTable.stackPointer
  vt.exceptionHandler = c_vectorTable.exceptionHandler
  for i in 0 ..< plat.platInterruptCount:
    vt.interruptHandler[i] = unusedSlot

proc setInterruptHandler(irqNmbr: InterruptNmbr, handler: InterruptHandler) =
  ## Sets the interrupt handler for the given interrupt number.
  assert irqNmbr.uint < plat.platInterruptCount,
    "Interrupt number exceeds project-defined limit."
  vt.interruptHandler[irqNmbr.int] = handler
