# KRNL Configuration Dependencies

This document enumerates the platform-specific items
consumed by KRNL that MUST be provided by the project
through the `plat.nim` module.

## Platform-specific items needed by KRNL

| Identifier | type | explanation | options |
|---- |---- |---- |---- |
| platInterruptCount | int | The quantity of interrupts (not exceptions) available in the processor | 0 .. 512 |
| platFpuAvail | bool | Whether the core has an FPU | true | false |
| platNvicPrioShift | uint32 | The processor's nvicPriorityBits (usually from the cpu element of the SVD) | 0 .. 7 |
