## Copyright 2026 Dean Hall See LICENSE for details
##
## KRNL ActrSet type
##

import plat
import bitflags

type ActrSet* = Bitflags[plat.irqCnt()]

