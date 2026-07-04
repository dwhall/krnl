## Copyright 2026 Dean Hall See LICENSE for details
##
## KRNL broadly used types and converters

import plat

type
  ExceptionNmbr* = 1 .. 16 + plat.platInterruptCount # ARM Exception number
  InterruptNmbr* = 0 .. plat.platInterruptCount - 1 # ARM Interrupt number

converter toInterruptNumber*(exnNmbr: ExceptionNmbr): InterruptNmbr =
  ## Converts an exception number to an interrupt number
  assert exnNmbr.int >= 16, "Exceptions lower than 16 are not interrupts"
  InterruptNmbr(exnNmbr.int - 16)
