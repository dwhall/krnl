##
## RingQue: a static sized, type-generic circular queue.
##
## This type is intended for use within kernels in deeply embedded systems.
## We make the queue's size static, meaning it must be known at compile time
## so that the queue can be allocated on the stack if desired.
##
## Copyright 2024 Dean Hall See LICENSE for details
##

type
  RingQueIndexType = uint8
  RingQue*[N: static RingQueIndexType, T] = object
    buf: array[N, T]
    count: range[0.RingQueIndexType .. N]
    readIdx: range[0.RingQueIndexType .. N]
    writeIdx: range[0.RingQueIndexType .. N]

let qFullIndexDefect = newException(IndexDefect, "Queue is full")
let qEmptyIndexDefect = newException(IndexDefect, "Queue is empty")

proc newRingQue*(n: static RingQueIndexType, t: typedesc): auto =
  ## Creates a new RingQue of size n and type t
  RingQue[n, t]()

func cap*[N, T](self: RingQue[N, T]): auto {.inline.} =
  ## Returns the capacity of the queue
  N

proc add*[N, T](self: var RingQue[N, T], item: sink T) {.inline.} =
  ## Raises an IndexDefect if the queue is already full.
  ## Adds the item to the writeIdx position of the queue,
  ## then moves the writeIdx.
  if self.full:
    raise qFullIndexDefect
  self.buf[self.writeIdx.int] = item
  if self.writeIdx == 0:
    self.writeIdx = N
  dec self.writeIdx
  inc self.count

proc pop*[N, T](self: var RingQue[N, T]): owned T {.inline.} =
  ## Raises an IndexDefect if the queue is already empty.
  ## Removes and returns the item at the readIdx position of the queue,
  ## then moves the readIdx.
  if self.count == 0:
    raise qEmptyIndexDefect
  result = self.buf[self.readIdx.int]
  if self.readIdx == 0:
    self.readIdx = N
  dec self.readIdx
  dec self.count

func len*[N, T](self: RingQue[N, T]): auto {.inline.} =
  ## Returns the current number of items in the queue
  self.count

func clear*[N, T](self: var RingQue[N, T]) {.inline.} =
  ## Empties the circular queue
  self.readIdx = 0
  self.writeIdx = 0
  self.count = 0

func full*[N, T](self: RingQue[N, T]): bool {.inline.} =
  ## Returns whether the buffer is completely full
  self.count == N

proc `=copy`[N, T](
  dst: var RingQue[N, T], src: RingQue[N, T]
) {.error: "RingQue is owned and cannot be copied".}
  ## Prevent a RingQue from being copied because they are owned by a Task
