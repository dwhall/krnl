# KRNL Vector Table

## Overview

KRNL uses two vector tables: a **boot VT** in flash for the boot/init sequence,
which includes bootloading, and an **application VT** in RAM that replaces it
via a one-time VTOR write after all tasks have registered.
The application VT uses compile-time-generated ISR stubs per slot
to eliminate all runtime dispatch overhead.

## Boot Vector Table

Resides in flash at the reset address (linker-placed).

Exception slots (Reset, NMI, HardFault, etc.) hold default exception handlers.
Some Interrupt slots are used for booting or bootloading.

The boot sequence is expected to use at minimum:

- A hardware timer (timeout, retry logic)
- One or more communications peripherals (UART, USB, etc.)
- A non-volatile storage controller (flash read/write)

These peripherals' exception/IRQ slots must be populated in the boot VT
before their interrupts are enabled. The specific handlers are
bootloader-defined and outside the scope of this document.

## Application Vector Table

A `VectorTable` object allocated in RAM.

**Alignment:** VTOR requires the table to be aligned to the next power-of-two value
greater than or equal to `(16 + PLAT_IRQ_CNT) × 4` bytes. The linker script or
compiler alignment directive must enforce this.

**Size:** `(16 + PLAT_IRQ_CNT) × 4` bytes. For 64 IRQs: 320 bytes before alignment
padding.

Exception slots [0..15] are copied from the boot VT or re-specified at init time.
IRQ slots [16..16+N-1] are populated during task registration.

### VTOR Switch

After all tasks have registered and before any task is launched, KRNL writes:

```
SCB.VTOR = address of appVT
```

This is a **one-time, irreversible** transition. If a dynamically-loaded software
package is removed, the system must reboot rather than attempt to undo registration.

## ISR Modes

Each IRQ slot operates in exactly one mode, assigned at registration.  Once registered,
the slot remains in that mode for runtime.  Only unused slots may change to another mode
during runtime:

| Mode | Trigger | Action |
|------|---------|--------|
| **Unused** | None | The slot is not used for peripheral interrupt or task dispatch and contains a known handler that indicates the slot is unused
| **Event-post** | Hardware peripheral IRQ fires | Post the platform Signal corresponding to this IRQ into the assigned task's event queue; pend that task's dispatch IRQ |
| **Schedule-task** | Task's own dispatch IRQ is pended by the NVIC scheduler | Pop the next event from the task's queue; invoke the task's state handler |

Peripheral IRQ slots are assigned event-post mode. Slots not claimed by
a peripheral are then available for KRNL's NVIC-based task dispatch.

### Platform Signals for Event-Post

A project-specific component defines a constant `Signal` value for each platform
interrupt, in a 1:1 mapping to the interrupt numbering of the target Cortex-M device.
These constants change per microcontroller family. The event-post ISR uses its
slot index (a compile-time literal) to select the corresponding Signal constant and
post `Evnt(sig: platformSignal[n], val: ...)` to the task's queue.

## Compile-Time ISR Stubs

For vector table slots that dispatch tasks, there will be procedures like this
or a template or macro that generates code like this:

```nim
proc dispatchIrq17(schd: Scheduler) =
  ## Declares a dispatch procedure for the task with irqNmbr 17.
  ## This procedure's only use is to be placed in the vector table.
  schd.dispatch(17)
```

and there is a common dispatch function (WIP):

```nim
proc dispatch(schd: Scheduler, irqNmbr: static IrqNmbr) =
  ## Dispatches the next event to the task with the given irqNmbr.
  ## ATTENTION: This procedure is called in the handler context
  const task = schd.getTask(irqNmbr)
  let
    # FIXME: put these in the named registers
    R0 = task.popEvent()
    LR = task.eventHandler
    # TODO: return from interrupt
```

For vector table slots that post events, there will be procedures like this
or a template or macro that generates code like this:

```nim
proc postIrq17Event(schd: Scheduler) =
  ## Declares a procedure that posts an event that signals Interrupt 17
  schd.postIrqEvent(17)
```

and there is a common postIrq function (WIP):

```nim
# TODO
```

**Flash cost:** `2 × PLAT_IRQ_CNT` stubs × ~8 bytes each.
For 64 IRQs: ~1 KB of flash.

## Task Registration

Called by each task (or its software package) during the boot/init phase, before the
VTOR switch:

1. Task declares which interrupt number(s) it consumes for the peripheral(s) is uses.
2. Task requests a slot in the VT, receives an `irqNmbr`
3. Scheduler stores `ref Task` in `gKrnlCtx.scheduler.taskRegistry[irqNmbr]`.
3. Scheduler writes the appropriate stub address into the RAM VT slot:
   - Event-post: `appVT[irqNmbr] = addr(postEvtIrq_n)`
   - Schedule-task: `appVT[irqNmbr] = addr(schedTaskIrq_n)`
4. Scheduler configures NVIC priority for the IRQ.
5. The IRQ remains disabled until KRNL activates the task after the VTOR switch.

## Dispatch Path

### Event-Post (peripheral IRQ fires)

```
NVIC fetches vector from appVT[n]
  → postEvtIrq_n()                    (n is compile-time literal, no IPSR read)
  → postEvtCommon(n)
    → task = taskRegistry[n]          (fixed address, link-time resolved)
    → publish Evnt(platformSignal[n]) to its subscribers
    → subscriber tasks are scheduled via pending their bits in the NVIC
  ← exception return → NVIC activates pended interrupts in priority order, tail-chaining along the way
```

### Schedule-Task (task dispatch IRQ fires)

```
NVIC fetches vector from appVT[n]
  → schedTaskIrq_n()                  (n is compile-time literal, no IPSR read)
  → schedTaskCommon(n)
    → task = taskRegistry[n]          (fixed address, link-time resolved)
    → evnt = task.eventQue.pop()
    → task.eventHandler(evnt)
  ← exception return → NVIC tail-chains to next pending task
```

## Efficiency vs. Flash-VT Alternative

The alternative (flash VT + single shared master handler + RAM LUTs) was considered
and rejected:

| | Flash VT + master handler | **RAM VT + stubs (chosen)** |
|---|---|---|
| Mode determination | IPSR read + mode LUT | None (VT entry encodes mode) |
| Target lookup | Runtime indexed LUT | Fixed address (link-time constant) |
| Cycles overhead | ~7–8 cycles | ~2–3 cycles |
| Flash cost | Negligible | ~1 KB (64 IRQs) |
| RAM cost | Mode + target LUTs | VT + alignment padding |
| VTOR manipulation | None | One-time at boot |

The RAM VT approach eliminates the IPSR read, mode branch, and runtime index
arithmetic from every interrupt and every task context switch. This directly benefits
tail-chaining throughput, which is central to KRNL's scheduling model.

## Data Structures

```
# In Scheduler (within KrnlCtx):
taskRegistry: array[PLAT_IRQ_CNT, ref Task]

# In RAM (linker-aligned):
appVT: VectorTable

# Project-specific (per target device):
platformSignal: array[PLAT_IRQ_CNT, Signal]  # constant, 1:1 to IRQ numbering
```
