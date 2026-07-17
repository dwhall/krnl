## Copyright 2026 Dean Hall See LICENSE for details
##
## KRNL ActrRegistry
##
## KRNL maintains a set of Actrs and reserves an entry in the
## NVIC's Vector Table in order to activate the Actr's event handler.
## Actr's must register with KRNL in order to perform syscalls to
## register, publish and subscribe to events, which is the primary
## method of being pended for activation (execute code).
##

import actr, vectortable

type ActrRegistry*[N: static uint8] = object
  actrs: array[IrqNmbr, ptr Actr[N]]

func registerActr*(self: var ActrRegistry, actr: ptr Actr, irqNmbr: IrqNmbr) =
  ## Registers an actr with the registry.  The actr's irqNmbr is used to
  ## identify the actr in this registry.
  self.actrs[irqNmbr] = actr

func getActr*(self: ActrRegistry, irqNmbr: IrqNmbr): ptr Actr {.inline.} =
  ## Returns the actr registered with the given interrupt number
  ## ATTENTION: This procedure is called in the handler context
  result = self.actrs[irqNmbr]
  assert result != nil and result.irqNmbr == irqNmbr, "Actr not registered"
