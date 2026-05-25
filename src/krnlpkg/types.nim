import ringque

type # TODO: these should come from the ARM core import
  ExceptionNmbr* = uint16 # ARM Exception number
  InterruptNmbr* = uint16 # ARM Interrupt number

type
  Signal* = int32
  Evnt*[T] = object
    sig*: Signal
    val*: T

  Task*[N: static uint8, T] = object
    # Are these AWSM-specific?
    # init*: proc(self: var Task[N, T], e: Evnt[T])
    # dispatch*: proc(self: var Task[N, T], e: Evnt[T])
    eventQue*: RingQue[N, T]
    irqNmbr*: InterruptNmbr # serves as unique identifier

  TaskPrio* = uint8 # 0 is the lowest priority
  NvicPrio* = uint8 # 0 is the highest priority

# TODO: this should be in an ARM core module
converter toInterruptNumber*(exnNmbr: ExceptionNmbr): InterruptNmbr =
  ## Converts an exception number to an interrupt number
  exnNmbr - 16'u16
