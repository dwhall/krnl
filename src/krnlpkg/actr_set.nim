## Copyright 2026 Dean Hall See LICENSE for details
##
## KRNL ActrSet type
##
## An ActrSet is a Bitflags where each bit corresponds to an actr's interrupt number.
## The quantity of interrupt numbers available depends on the platform/processor.
## The number of bits used in the Bitflags type must be determined at compile time.

import bitflags
import plat

type ActrSet* = Bitflags[platInterruptCount]
