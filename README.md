# KRNL

An event-based microkernel with memory protection for ARM Cortex-M devices.
A translation of Miro Samek's
[Super Simple Tasker (SST)](https://github.com/QuantumLeaps/Super-Simple-Tasker)
into the Nim language, with these differences:

* Port strictly to the ARM Cortex-M devices with a Memory Protection Unit (MPU)
* Tasks must be assigned to a protected memory context

