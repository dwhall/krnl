# KRNL Configuration Dependencies

This document enumerates the platform-specific items
consumed by KRNL that MUST be provided by the project
through the `plat.nim` module.

## Platform-specific items needed by KRNL

| Identifier | type | explanation | options |
|---- |---- |---- |---- |
| irqCnt | int | The quantity of interrupts (not exceptions) available in the processor | 0 .. 512 |
| fpuAvail | bool | Whether the processor has a floating point unit (FPU) (usually from the cpu element of the SVD) | true | false |
| nvicPriorityBits | int | The number of priority bits implemented in the NVIC (usually from the cpu element of the SVD) | 0 .. 7 |
