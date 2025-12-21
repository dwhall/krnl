# KRNL

A minimalist event-based microkernel with memory protection for ARM Cortex-M devices.

A translation of Miro Samek's QPC and
[Super Simple Tasker (SST)](https://github.com/QuantumLeaps/Super-Simple-Tasker)
rewritten in the Nim language.

Port strictly to the ARM Cortex-M devices that have a Memory Protection Unit (MPU).
* Tasks must be assigned to a protected memory context

Things to keep OUT of the microkernel:

* Messages - Variable length, application-level messages: (time, src, dst, payld), any bus
* Device Drivers that do NOT directly support microkernel objects.

## References

ARM Cortex-M SVD files:
    https://github.com/ARM-software/CMSIS_5/tree/develop/Device/ARM/SVD
Patched STM32 SVD files:
    https://github.com/tinygo-org/stm32-svd