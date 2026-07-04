## Copyright 2026 Dean Hall See LICENSE for details
##

import plat

type
  ActrPriority* = uint8 # 0 is the lowest priority
  NvicPriority* = uint8 # 0 is the highest priority

converter toNvicPriority*(prio: ActrPriority): NvicPriority =
  ## Converts ActrPriority where 0 is the lowest priority
  ## to NvicPriority where 0 is the highest priority
  NvicPriority(
    ((0xFF'u32 shr plat.platNvicPriorityBits) + 1'u32 - prio) shl
      plat.platNvicPriorityBits
  )
