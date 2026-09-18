## Copyright 2026 Dean Hall See LICENSE for details
##
## Platform-specific definition stubs for testing

func irqCnt*(): int {.compileTime.} =
  48

func fpuAvail*(): bool {.compileTime.} =
  true

func nvicPriorityBits*(): int {.compileTime.} =
  3

func vtorAlignment*(): int {.compileTime.} =
  128
