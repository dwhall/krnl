# KRNL

A minimalist microkernel
for ARM Cortex-M devices with an MPU
written in [Nim](https://nim-lang.org/)

Borrows on ideas from:
* Miro Samek's [Super Simple Tasker (SST)](https://github.com/QuantumLeaps/Super-Simple-Tasker)
* [seL4](https://sel4.systems/About/)

Things that belong in the microkernel:
* Memory management, protection and DMA
* Interrupt handling
* Event dispatch to Tasks

Things to keep OUT of the microkernel:
* Messages - Variable length, application-level messages: (time, src, dst, payld), any bus
* Device Drivers that do NOT directly support microkernel objects.
