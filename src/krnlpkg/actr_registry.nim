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

import std/tables
import actr, vectortable

type
  ActrRegistry* = object
    actrs: Table[IrqNmbr, pointer]

proc registerActr*(self: var ActrRegistry, actr: ptr Actr, irqNmbr: IrqNmbr) =
  ## Registers an actr with the registry.  The actr's irqNmbr is used to
  ## identify the actr in the registry and to reserve an entry in the NVIC's
  ## Vector Table for activation.
  # TODO: What do we do if the irqNmbr is already in the registry?
  # TODO: What do we do if the actr is already in the registry?
  assert irqNmbr notin self.actrs, "Actr already registered"
  self.actrs[irqNmbr] = actr
