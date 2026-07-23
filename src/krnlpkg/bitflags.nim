## Copyright 2026 Dean Hall See LICENSE for details
##
## Bitflags datatype for KRNL
##
## This is a simple implementation of a bitflags, which is a set of
## bits in an array of 32-bit words.  The number of bits is
## determined at compile time by the template parameter Nb.
##
## We are not using Nim's built-in set datatype because we wish to determine
## the exact bit layout of the flags because the bit pattern will be used
## with the NVIC's pending registers.

import std/math

type Bitflags*[Nb: static int] = object
  flags: array[(Nb + 31) div 32, uint32]
  card: uint16 # number of bits currently set

proc cap*[Nb: static int](self: Bitflags[Nb]): uint16 =
  ## Returns the capacity of the bitflags, which is the declared number of bits,
  Nb

proc card*(self: Bitflags): uint16 =
  ## Returns the number of bits currently set in the bitflags
  self.card

proc incl*[Nb: static int](self: var Bitflags[Nb], flagIdx: range[0 .. (Nb - 1)]) =
  ## Sets the flagIdx in the bitflags
  let (wordIdx, bitIdx) = divmod(flagIdx.int32, 32)
  let alreadySet = (self.flags[wordIdx] and (1'u32 shl bitIdx)) != 0'u32
  if not alreadySet:
    inc self.card
    self.flags[wordIdx] = self.flags[wordIdx] or (1'u32 shl bitIdx)

proc excl*[Nb: static int](self: var Bitflags[Nb], flagIdx: range[0 .. (Nb - 1)]) =
  ## Clears the flagIdx in the bitflags
  let (wordIdx, bitIdx) = divmod(flagIdx.int32, 32)
  let alreadySet = (self.flags[wordIdx] and (1'u32 shl bitIdx)) != 0'u32
  if alreadySet:
    dec self.card
    self.flags[wordIdx] = self.flags[wordIdx] and not (1'u32 shl bitIdx)

proc contains*[Nb: static int](
    self: Bitflags[Nb], flagIdx: range[0 .. (Nb - 1)]
): bool =
  ## Returns true if the flagIdx is set in the bitflags, false otherwise
  let (wordIdx, bitIdx) = divmod(flagIdx.int32, 32)
  (self.flags[wordIdx] and (1'u32 shl bitIdx)) != 0'u32

proc isEmpty*(self: Bitflags): bool =
  ## Returns true if no flags are set in the bitflags, false otherwise
  self.card == 0

iterator items*(self: Bitflags): uint32 =
  ## Yields word-sized sets of flags from least to greatest
  for i in self.flags:
    yield i

proc `[]`*(self: Bitflags, i: uint8): uint32 =
  ## Returns the i-th 32-bit wide group of flags, where i is in the range [0, Nb div 32)
  assert i < self.flags.len.uint
  self.flags[i]
