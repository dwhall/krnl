## Copyright 2026 Dean Hall See LICENSE for details
##
## KRNL TaskSet type
##
## A TaskSet is a Bitflags where each bit corresponds to a task's interrupt number.
## The quantity of interrupt numbers available depends on the platform/processor.
## The number of bits used in the Bitflags type must be determined at compile time.

import bitflags

# TODO: this should be determined at compile time 
# based on the platform/processor
const platInterruptCount {.intdefine.}: uint16 = 64

type TaskSet* = Bitflags[platInterruptCount]
