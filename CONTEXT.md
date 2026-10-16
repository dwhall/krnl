# KRNL Project Context

## What is KRNL?
A microkernel written in Nim for 32-bit ARM Cortex-M devices, servicing
actors with event-driven, run-to-completion semantics on a single stack
using the ARM core's NVIC for hardware-accelerated context switching.
KRNL also carries the ARMv7-M platform support (`src/plat/`) that a project
builds on; a project (e.g. c2lora) includes KRNL as a git submodule.

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
- Privilege: actrs run unprivileged and reach the kernel through syscalls (`svc`).
    Procs that need privileged mode are tagged `PrivilegedModeEffect`;
    an EventHandler may declare `{.forbids: [PrivilegedModeEffect].}` so the compiler checks it.
- Memory: static allocation preferred for in-kernel objects; heap allocation (ref objects) should be used judiciously
- Memory management: Nim `arc` or `orc` for real-time use where needed
- Nim stdlib: used selectively; must favor static memory allocation
- Exceptions: avoided in the kernel initially; may be reconsidered
- MPU memory protection: details TBD; may constrain per-Actr or per-partition

## Gotchas
- Never issue an SVC (any `syscall*` proc) from Handler mode (an ISR).
  ISRs are already privileged and call the kernel procs (e.g. `publishEvent`) directly.
- `ActrPriority` 0 is the LOWEST priority; NVIC priority 0 is the HIGHEST.
  NVIC level 0 is reserved for device ISRs so an actr's dispatch ISR always
  tail-chains after a device ISR that posts to it, never preempts it.

## Major Components
| Component | Module(s) | Description | Status |
|-----------|-----------|-------------|--------|
| `krnl`    | `krnl_impl/krnl` | Kernel init, RAM vector table, NVIC priority setup, actr dispatch, actr registry (vector table slot per Actr) | Working |
| `syscall` | `krnl_intf/syscall`, `krnl_impl/syscall` | SVC interface: register actr/signals/IRQ handler, subscribe, postEvent, publishEvent | Working |
| `signal`, `namespace` | `krnl_intf/signal`, `krnl_intf/namespace` | Signals named by dotted namespaces, hashed to compact values | Working |
| `signal registry` | `krnl_impl/signal_registry` | Actrs register the signals they provide and subscribe to the signals they need | Working |
| `event`   | `krnl_intf/event` | A coupled Signal and value either published through the krnl to subscribers or posted directly to an actr | Working |
| `systimer` | `krnl_impl/systimer`, `plat/<platform>/timer_<platform>` | 64-bit SysTick; project timers (declared by the project, published to subscribers after init) and private timers (one actr; one-shot or periodic) | Working |
| `system events` | | The krnl has a small set of defined events that EITHER all actrs MUST respond to, OR are of significant utility to most actrs. | Not started |
| `event queue` | `krnl_impl/ringque` | An actr's event queue receives and serializes incoming events.  Events are processed in FIFO order. | Working, but limited exercise |
| `actr set` | `krnl_intf/actr_set`, `krnl_intf/bitflags` | Bitflags of actr IrqNmbr laid out to match the NVIC pending registers | Working |
| `plat`    | `plat/` | Platform (processor) config, settings and management.  Boot, reset, vector table, RTT debug output, per-MCU support (`nrf52` is first platform) | Working |
| `awsm`    | | Actrs With State Machines: actrs update their event handler to effect a hierarchical state machine | Not started |
| `prot`    | | Use MPU hardware to establish memory and peripheral protection | Far back burner |

## Coding Conventions
- Language: Nim 2.x (requires "nim >= 2.0.0").
- Indentation: 2 spaces, no tabs; aim for short lines (~100 cols).
- Naming: types in PascalCase, procs/vars/constants in camelCase, constants from C in UPPER_SNAKE_CASE
- Abbreviations follow `GLOSSARY.md` (actr, irq, nmbr, cnt, intf, ...)
- Follow [NEP 1](https://nim-lang.org/docs/nep1.html) (Nim community style guide)
- Formatted with [nph](https://github.com/arnetheduck/nph)
- Formatting may be disabled locally (`#!fmt: off`) when it improves clarity, aligns repeated code, or increases compactness

## Source Layout & Imports
| Folder | Contents | Who may import it |
|---|---|---|
| `src/krnl_intf/` | KRNL interface modules; types shared between kernel and userland.  Kernel-related operations that don't need privileged-mode access. | Application modules (and anyone) |
| `src/krnl_impl/` | Kernel implementation; usually requires privileged-mode acceess. | krnl, `plat/` and project-support modules only |
| `src/plat/` | Generic ARMv7-M platform support | krnl and project-support modules |
| `src/plat/<platform>/` | One MCU's modules, named `*_<platform>.nim` | same as `plat/` |

- Contract modules are imported by bare name and resolved via the search path,
  so the tests can substitute stubs (`tests/stubs/`):
  `plat`, `vectortable` (krnl's `plat/`), `plat_<platform>` and `proj` (provided by the project).
- Siblings are imported relatively: `import actr, event`; other krnl folders by relative path
  (e.g. `import ../../krnl_impl/systimer`).
- Project code imports krnl by qualified path, never bare names (e.g. `plat/debug_rtt`).
- Import order: `std/`, third-party (`armv7m/`, `nrf52840/`, ...), contract modules, krnl modules.

## Platform & Project Contracts
- `plat.nim` defines the `Platform` concept and `include`s `plat_<platform>` selected by
  `-d:platform=<platform>`; an unknown value is a compile error.
  A platform provides compile-time `irqCnt`, `fpuAvail`, `nvicPriorityBits`, `vtorAlignment`
  and a run-time `initPlat`.
- The project's `proj` module provides `EventValue` (see `deps/cnfg/proj.md`).
- Adding an ARMv7-M MCU: create `src/plat/<mcu>/`, add a case to `plat.nim`, set `platform`.

## Building (from the project)
KRNL is not built on its own for hardware; the project's `config.nims` supplies:
- `--path:` for `deps/krnl/src`, `deps/krnl/src/plat`, `deps/krnl/src/plat/<platform>`, `src`, `src/proj`
- `-d:platform=<platform>`
- `-d:rttPath=<abs path>` to a SEGGER RTT checkout for `debug` builds
  (otherwise `plat/debug_rtt` looks for `deps/RTT` beside krnl)
- `debug_rtt` uses the third-party `pathX` package (see `krnl.nimble`).

## Testing Guidelines
- Test framework: [unittest2](https://github.com/status-im/nim-unittest2)
- Tests live in `tests/` as `test_*.nim`; `*.nim.disable` files are parked tests.
- Run all tests with `nim test` (task in `config.nims`; compiles each with `--skipParentCfg`).
- `tests/config.nims` puts `tests/stubs/` (stub `plat`, `proj`) ahead of the real modules
  and defines `domain=test`.
- Test Driven Design is strongly recommended for green-field development

## Working With LLM or AI
- This project is created by humans
- LLM/AI may be used to assist, but is not allowed open-ended operation
- Use the developer's LLM/AI preferences
- Reference this doc at the start of each session
