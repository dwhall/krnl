import ringque

type
  ExceptionNmbr* = distinct uint16 # ARM Exception number
  InterruptNmbr* = distinct uint16 # ARM Interrupt number

  TaskPriority* = uint8 # 0 is the lowest priority
  NvicPriority* = uint8 # 0 is the highest priority

  Signal* = int32
  Evnt*[T] = object
    sig*: Signal
    val*: T

  Task*[N: static uint8, T] = object
    # Are these AWSM-specific?
    # init*: proc(self: var Task[N, T], e: Evnt[T])
    # dispatch*: proc(self: var Task[N, T], e: Evnt[T])
    eventQue*: RingQue[N, Evnt[T]]
    irqNmbr*: InterruptNmbr # serves as unique identifier

converter toInterruptNumber*(exnNmbr: ExceptionNmbr): InterruptNmbr =
  ## Converts an exception number to an interrupt number
  result = InterruptNmbr(exnNmbr.uint16 - 16'u16)

converter toNvicPriority(prio: TaskPriority): NvicPriority =
  ## Converts TaskPriority where 0 is the lowest priority
  ## to NvicPriority where 0 is the highest priority
  # TODO: const nvicPrioShift = cpu.nvicPrioBits.uint32
  const nvicPrioShift = 4 # FIXME
  ((0xFF'u32 shr nvicPrioShift) + 1'u32 - prio) shl nvicPrioShift
