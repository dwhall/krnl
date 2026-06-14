# KRNL Configuration Dependencies

This document enumerates the project-specific items
REQUIRED by KRNL that must be provided by the project
through the `proj.nim` module.

## Project-specific items needed by KRNL

| Identifier | type | explanation | options |
|---- |---- |---- |---- |
| EventValue | type | The datatype used for the `.value` field of the Event type | type of fixed, preferably small size |
