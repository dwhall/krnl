## Copyright 2026 Dean Hall See LICENSE for details
##
## Platform-specific definitions needed by KRNL
##

type Platform* =
  concept
      ## Compile time constants
      ## The quantity of interrupts (not exceptions) available in the processor
      func irqCnt(): int {.compileTime.}
      ## Whether the processor has a floating point unit (FPU)
      func fpuAvail(): bool {.compileTime.}
      ## The number of priority bits implemented in the NVIC
      func nvicPriorityBits(): int {.compileTime.}
      ## The memory alignment required for the vector table (VTOR)
      func vtorAlignment(): int {.compileTime.}

      ## Run time functions
      ## Platform initialization
      func initPlat()

const platform {.strdefine.} = ""
when platform == "nrf52":
  include plat_nrf52
else:
  {.error: "`platform` MUST be defined to a value with a match in plat.nim".}

type IrqNmbr* = range[0 .. irqCnt() - 1] # interrupts are external to the ARM core
