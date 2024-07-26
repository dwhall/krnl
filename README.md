# KRNL

An event-based microkernel with memory protection for ARM Cortex-M devices.
A translation of Miro Samek's
[Super Simple Tasker (SST)](https://github.com/QuantumLeaps/Super-Simple-Tasker)
into the Nim language, with these differences:

* Port strictly to the ARM Cortex-M devices that have a Memory Protection Unit (MPU)
* Tasks must be assigned to a protected memory context


## References

ARM Cortex-M SVD files:
    https://github.com/ARM-software/CMSIS_5/tree/develop/Device/ARM/SVD
