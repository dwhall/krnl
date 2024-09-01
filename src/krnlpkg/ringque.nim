##
## RingQue: a fixed-size, type-generic circular queue
##
## Copyright 2024 Dean Hall See LICENSE for details
##

type
  RingQueIndex = Natural
  RingQue*[N: static RingQueIndex, T] = object
    buf: array[N, T]
    readIdx, writeIdx, count: RingQueIndex

let qFullError = newException(IndexDefect, "Queue is full")
let qEmptyError = newException(IndexDefect, "Queue is empty")

template cap*[N, T](self: RingQue[N, T]): RingQueIndex =
  ## Returns the capacity of the queue
  N

template add*[N, T](self: var RingQue[N, T], item: T) =
  ## Adds the item to the writeIdx position of the queue.
  ## Raises an IndexDefect if the queue is already full.
  if self.full:
    raise qFullError
  self.buf[self.writeIdx] = item
  if self.writeIdx == 0:
    self.writeIdx = self.cap
  dec self.writeIdx
  inc self.count

template pop*[N, T](self: var RingQue[N, T]): T =
  ## Removes and returns the item at the readIdx position of the queue.
  ## Raises an IndexDefect if the queue is empty.
  if self.count == 0:
    raise qEmptyError
  let result = self.buf[self.readIdx]
  if self.readIdx == 0:
    self.readIdx = self.cap
  dec self.readIdx
  dec self.count
  result

template len*[N, T](self: RingQue[N, T]): RingQueIndex =
  ## Returns the current number of items in the queue
  self.count

template full*[N, T](self: RingQue[N, T]): bool =
  ## Returns whether the buffer is full
  self.count == self.cap

when isMainModule:
  var c: RingQue[32.RingQueIndex, int64]
  c.add(3'i64)
  c.add(2'i64)
  c.add(1'i64)
  discard c.pop()
  echo $c.pop()
  echo $c.cap
