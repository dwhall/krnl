# KRNL

An event-driven microkernel
for ARM Cortex-M (ARMv7m and v8m) devices
written in [Nim](https://nim-lang.org/)

Borrows on ideas from:
* Miro Samek's [Super Simple Tasker (SST)](https://github.com/QuantumLeaps/Super-Simple-Tasker)
* [seL4](https://sel4.systems/About/)

Things that belong in the microkernel:
* Task registration
* Event dispatch to Tasks
* NVIC-accelerated scheduler
* Interrupt handling
* Memory management and DMA
* System time management
* SBOM and Capabilities security
* Cryptographic identity and authentication

Things to keep OUT of the microkernel:
* Message Passing - Variable length, application-level messages: (time, src, dst, payld), any bus
    - instead, a user-space service manages zero-copy messaging; employs Kernel event.
* Device Drivers that do NOT directly support microkernel objects.
