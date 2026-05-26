# KRNL Signal

## Overview

A `Signal` is a 32-bit value that uniquely identifies the type of event that has occurred.
Signals are the first field of an `Event` object: `Event = (Signal, Value)`.

Signal values encode both the **source** (package + module) and the **signal index** within
that source. Uniqueness is guaranteed across all software in the system.

---

## Bit Layout

The highest bit (bit 31) selects between two field-width variants:

```
Bit 31 = 0  →  Short form:  [ 0 | source: 23 bits | index: 8 bits  ]
Bit 31 = 1  →  Long form:   [ 1 | source: 21 bits | index: 10 bits ]
```

| Form  | Selector | Source field | Index field | Max signals/source |
|-------|----------|-------------|-------------|-------------------|
| Short | `0`      | 23 bits     | 8 bits      | 256               |
| Long  | `1`      | 21 bits     | 10 bits     | 1024              |

The source field holds a **truncated namespace hash** (see below).
A module selects the form based on how many signals it declares.

---

## Source Identification

Each signal source (software module or Actor) is identified by a dotted namespace string:

```
<business group>.<package>
```

KRNL itself is a source and registers like any other module, with the exception that
certain KRNL-internal signals used during early boot/init may be available before full
registration is complete.

### Hash Generation

1. Compute the 32-bit hash of the namespace string.
2. Truncate to 23 bits (short form) or 21 bits (long form).
3. Verify uniqueness at compile time (see [Uniqueness Guarantee](#uniqueness-guarantee)).

---

## Signal Registry

KRNL maintains a Signal Registry built at boot/init and updated as modules are loaded.
It is intentionally minimal to conserve memory.

### Registry Entry

```nim
type SignalRegistryEntry = object
  sourceHash: uint32   ## truncated namespace hash (source field of Signal)
  maxIndex:   uint16   ## highest signal index declared by this source
```

Only one entry per source is stored. Individual signal names are not registered.

### Lifecycle

| Event                    | Registry Action                                          |
|--------------------------|----------------------------------------------------------|
| KRNL boot                | KRNL registers its own source entry                      |
| Module loaded/registered | Module registers its source entry                        |
| Module re-registered     | Entry updated; KRNL broadcasts re-init notification      |
| Module unloaded          | Source entry removed immediately                         |

When a source re-registers (e.g., a replacement module), KRNL synthesizes and delivers
a re-init notification to all current subscribers of that source. This signals that the
source has undergone a state reset and subscribers should respond accordingly.

`maxIndex` must never decrease between registrations. Deprecated signal indices must be
reserved but left unused by the source. KRNL does not enforce this; it is the
developer's responsibility.

---

## Signal Subscription

Actors subscribe to specific `Signal` values via an SVC to KRNL. Before recording the
subscription, KRNL validates:

1. The source hash matches a registered entry.
2. The signal index is ≤ `maxIndex` for that entry.

If validation fails, the subscription is rejected. Actors must be designed to tolerate
a source being temporarily absent (e.g., during a module replacement).

### Subscriber Table

The subscriber table maps `Signal → bitflags of exception indices`, where each set bit
corresponds to the NVIC exception index of a subscribed Actor. When an Actor publishes
an event:

1. Actor calls KRNL via SVC.
2. KRNL looks up the exception index bitflag for that `Signal`.
3. KRNL copies the `Event` into each subscribed Actor's event queue.
4. KRNL sets each subscribed Actor's NVIC pending bit to schedule execution.

### KRNL Broadcast Signals

Signals originating from KRNL are delivered to all Actors without requiring subscription.
Actors receive these signals unconditionally; whether they are processed is up to the Actor.

Examples of KRNL broadcast signals include the source re-init notification described above.

---

## Uniqueness Guarantee

Signal uniqueness is enforced at two levels:

### Compile-time check

Each source module invokes a `compileTime` Nim function that:

1. Computes the truncated hash for the module's namespace.
2. Checks the value against a persistent hash table maintained by the business
   organization (mechanism is implementation-defined per organization).
3. Raises a compile error on collision.

Deprecated module hashes are removed from the active table and archived separately.
Archived hashes remain reserved and must not be reused.

### Runtime check

KRNL rejects duplicate `sourceHash` values at registration time (i.e., two loaded
modules may not share a source hash).

---

## Nim Type Sketch

```nim
type
  SignalForm* = enum
    sfShort  ## bit 31 = 0, 8-bit index
    sfLong   ## bit 31 = 1, 10-bit index

  Signal* = distinct uint32

const
  SignalFormBit*   = 31u
  ShortIndexBits*  = 8u
  LongIndexBits*   = 10u
  ShortSourceBits* = 23u
  LongSourceBits*  = 21u

func form*(s: Signal): SignalForm =
  if (s.uint32 shr SignalFormBit) == 0: sfShort else: sfLong

func sourceHash*(s: Signal): uint32 =
  case s.form
  of sfShort: (s.uint32 shr ShortIndexBits) and ((1u32 shl ShortSourceBits) - 1)
  of sfLong:  (s.uint32 shr LongIndexBits)  and ((1u32 shl LongSourceBits)  - 1)

func index*(s: Signal): uint32 =
  case s.form
  of sfShort: s.uint32 and ((1u32 shl ShortIndexBits) - 1)
  of sfLong:  s.uint32 and ((1u32 shl LongIndexBits)  - 1)
```

---

## Design Notes

- **No reserved range for KRNL signals.** KRNL signals are hashed and registered like
  any other source. Boot-time self-signalling is a noted exception pending further design.
- **Dynamic loading support.** Because signals are identified by hash rather than a
  static enum, new sources can be added at runtime without recompiling existing modules.
- **No per-signal registration.** Only `(sourceHash, maxIndex)` is stored per source,
  keeping registry memory proportional to the number of *sources*, not total signals.
- **Subscribers survive module replacement.** Subscriptions persist when a source
  unregisters. When the replacement module re-registers, KRNL delivers a re-init
  notification to all subscribers, allowing them to resynchronize state.
- **`maxIndex` is monotonically non-decreasing.** Deprecated signal indices must be
  reserved (not reused) by the source. This ensures existing subscribers always
  reference a valid index range.
