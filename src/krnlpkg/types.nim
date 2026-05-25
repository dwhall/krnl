import ringque

type
  Signal* = int32
  Evnt*[T] = object
    sig*: Signal
    val*: T

  ExceptionNmbr* = uint8 # ARM Exception number
  Task*[N: static uint8, T] = object
    init*: proc(self: var Task[N, T], e: Evnt[T])
    dispatch*: proc(self: var Task[N, T], e: Evnt[T])
    eventQue*: RingQue[N, T]
    exnNmbr*: ExceptionNmbr # can serve as unique identifier

  TaskPrio* = uint8 # 0 is the lowest priority
  NvicPrio* = uint8 # 0 is the highest priority
