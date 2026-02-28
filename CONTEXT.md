# KRNL Project Context

## What is KRNL?
A minimalist microkernel for ARM Cortex-M devices with an MPU, written in Nim.
Source: https://github.com/dwhall/krnl

## Design Goals & Constraints
- Target: all 32-bit Cortex-M devices that have an MPU
- NVIC hardware scheduler — tasks are dispatched via interrupt pending
- Event-driven tasks — each task processes one event at a time from its queue
- Run-to-completion (RTC) — each task runs to completion before the next is dispatched
- Shared stack — all tasks share a single stack
- Share-nothing — tasks do not share data; all inter-task communication is via event posting or message passing; no semaphores or mutexes
- MPU memory protection — details TBD; may constrain per-task or per-domain
- Memory: mostly static allocation; heap allowed after careful consideration
- Memory management: Nim `arc` or `orc` for real-time use where needed
- Exceptions: avoided in the kernel initially; may be reconsidered
- Nim stdlib: used selectively; must favor static memory allocation

## Major Components
| Component | Description | Status |
|-----------|-------------|--------|
| `krnl`    | Kernel init, NVIC priority setup, `runForever` loop | Rough draft |
| `scheduler` | Task activation, event posting, IRQ scheduling | Not started |
| `types`   | Core types: `Signal`, `Evnt[T]`, `Task[N,T]`, priorities | Rough draft |
| `ringque` | Static, type-generic circular event queue | Rough draft |
| AWSM      | Actors with State Machines — hierarchical state machine event-driven tasks | [Separate repo](https://github.com/dwhall/awsm) |
| `prot`    | Use MPU hardware to establish memory and peripheral protection | Not started |

## Coding Conventions
- Language: Nim 2.x (requires "nim >= 2.0.0").
- Indentation: 2 spaces, no tabs; aim for short lines (~100 cols).
- Naming: types CamelCase, procs/vars camelCase
- Follow [NEP 1](https://nim-lang.org/docs/nep1.html) (Nim community style guide)
- Formatted with [nph](https://github.com/arnetheduck/nph)
- Formatting may be disabled locally (`#!fmt: off`) when it improves clarity, aligns repeated code, or increases compactness

## Testing Guidelines
- Framework: [unittest2](https://github.com/status-im/nim-unittest2)
- Tests live in the `tests/` directory.
- Test Driven Design is strongly recommended for green-field development

## Working With LLM or AI
- This project is created by humans
- LLM/AI may be used to assist, but is not allowed open-ended operation
- Use the developer's LLM/AI preferences
- Reference this doc at the start of each session
