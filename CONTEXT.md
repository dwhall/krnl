# KRNL Project Context

## What is KRNL?
A microkernel written in Nim for 32-bit ARM Cortex-M devices, servicing
actors with event-driven, run-to-completion semantics on a single stack
using the ARM core's NVIC for hardware-accelerated context switching.

Source: https://github.com/dwhall/krnl

## Design Goals & Constraints
- Target: 32-bit ARM Cortex-M devices that have an MPU
- Actr: Event-driven actrs with an event queue, a priority level and possibly children
    * events are serialized into the actr's event queue
- NVIC hardware scheduler:
    * an Actr with a non-empty event queue is scheduled by pending its interrupt
    * multiple pending interrupts are processed in priority order using tail-chaining
- Run-to-completion (RTC): each Actr runs one event to completion before running the next event in its queue
- Single stack: all actrs and interrupts use a single stack
- Share-nothing: Actrs do not have references to another actr's data.
    Events and message passing with copy semantics are the only way actrs exchange data.
    Neither semaphores nor mutexes are used to control access to data.
- Interrupt handlers either:
    * service a kernel-level device driver or
    * post an event to a user-level device driver or
    * dispatch an event to one or more Actrs
    * do nothing
- Memory: static allocation preferred for in-kernel objects; heap allocation (ref objects) should be used judiciously
- Memory management: Nim `arc` or `orc` for real-time use where needed
- Nim stdlib: used selectively; must favor static memory allocation
- Exceptions: avoided in the kernel initially; may be reconsidered
- MPU memory protection: details TBD; may constrain per-Actr or per-partition

## Major Components
| Component | Description | Status |
|-----------|-------------|--------|
| `krnl`    | Kernel init, NVIC priority setup, `runForever` loop | Rough draft |
| `actr registry` | Vector table slot assignment for Actrs | In development |
| `signal registry` | Actrs register the signals they provide and subscribe to the signals they need | In development |
| `event`   | A coupled Signal and value either published through the krnl to subscribers or passed directly to a child actr.  | |
| `timer event` | The krnl config describes the set of rates to post timer events.  The krnl publishes the timer events.  Actrs subscribe to their desired timer events. |
| `system events` | The krnl has a small set of defined events that EITHER all actrs MUST respond to, OR are of significant utility to most actrs. |
| `event queue` | An actr's event queue receives and serializes incoming events.  Events are processed in FIFO order. | seems to be working |
| `awsm`    | Actrs With State Machines: actrs update their event handler to effect a hierarchical state machine | Just getting started |
| `prot`    | Use MPU hardware to establish memory and peripheral protection | Far back burner |

## Coding Conventions
- Language: Nim 2.x (requires "nim >= 2.0.0").
- Indentation: 2 spaces, no tabs; aim for short lines (~100 cols).
- Naming: types in PascalCase, procs/vars/constants in camelCase, constants from C in UPPER_SNAKE_CASE
- Follow [NEP 1](https://nim-lang.org/docs/nep1.html) (Nim community style guide)
- Formatted with [nph](https://github.com/arnetheduck/nph)
- Formatting may be disabled locally (`#!fmt: off`) when it improves clarity, aligns repeated code, or increases compactness

## Testing Guidelines
- Test framework: [unittest2](https://github.com/status-im/nim-unittest2)
- Tests live in the `tests/` directory.
- Test Driven Design is strongly recommended for green-field development

## Working With LLM or AI
- This project is created by humans
- LLM/AI may be used to assist, but is not allowed open-ended operation
- Use the developer's LLM/AI preferences
- Reference this doc at the start of each session
