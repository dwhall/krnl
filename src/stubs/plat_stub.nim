## Copyright 2026 Dean Hall See LICENSE for details
##
## Platform-specific definitions
## when no hardware platform is specified we use this stub file.
##

func irqCnt*(): int {.compileTime.} =
  48

func fpuAvail*(): bool {.compileTime.} =
  true

func nvicPriorityBits*(): int {.compileTime.} =
  3
