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

## Nb is the number of flags that shall be represented (1-bit per flag).
type Bitflags*[Nb: static int] = object
  flags: array[(Nb + 31) div 32, uint32] # round up to the next 32-bit word
  card: range[0 .. Nb] # number of bits currently set

proc cap*[Nb: static int](self: Bitflags[Nb]): int =
  ## Returns the capacity of the bitflags, which is the declared number of bits,
  Nb

proc card*(self: Bitflags): int =
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

proc words*[Nb: static int](
    self: Bitflags[Nb], idx: range[0 .. ((Nb + 31) div 32 - 1)]
): uint32 =
  ## Returns the idx-th 32-bit wide group of flags
  assert idx < self.flags.len
  self.flags[idx]

iterator words*(self: Bitflags): uint32 =
  ## Yields the 32-bit wide groups of flags from least to greatest
  for word in self.flags:
    yield word
