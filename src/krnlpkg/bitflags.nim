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

proc cap*(self: Bitflags): uint16 =
  ## Returns the capacity of the bitflags, which is the declared number of bits,
  ## Nb, rounded up to the next multiple of 32.
  self.flags.len.uint16 * 32'u16

proc card*(self: Bitflags): uint16 =
  ## Returns the number of bits currently set in the bitflags
  self.card

proc incl*(self: var Bitflags, flag: uint16) =
  ## Sets the flag in the bitflags
  assert flag < self.cap, "This flag does not fit within the declared Bitflags object"
  let (wordIdx, bitIdx) = divmod(flag, 32'u16)
  let alreadySet = (self.flags[wordIdx] and (1'u32 shl bitIdx)) != 0'u32
  if not alreadySet:
    inc self.card
    self.flags[wordIdx] = self.flags[wordIdx] or (1'u32 shl bitIdx)

proc excl*(self: var Bitflags, flag: uint16) =
  ## Clears the flag in the bitflags
  assert flag < self.cap, "This flag does not fit within the declared Bitflags object"
  let (wordIdx, bitIdx) = divmod(flag, 32'u16)
  let alreadySet = (self.flags[wordIdx] and (1'u32 shl bitIdx)) != 0'u32
  if alreadySet:
    dec self.card
    self.flags[wordIdx] = self.flags[wordIdx] and not (1'u32 shl bitIdx)

proc contains*(self: Bitflags, flag: uint16): bool =
  ## Returns true if the flag is set in the bitflags, false otherwise
  assert flag < self.cap, "This flag does not fit within the declared Bitflags object"
  let (wordIdx, bitIdx) = divmod(flag, 32'u16)
  (self.flags[wordIdx] and (1'u32 shl bitIdx)) != 0'u32

proc isEmpty*(self: Bitflags): bool =
  ## Returns true if no flags are set in the bitflags, false otherwise
  self.card == 0

proc `[]`*(self: Bitflags, i: uint8): uint32 =
  ## Returns the i-th 32-bit wide group of flags, where i is in the range [0, Nb div 32)
  assert i < self.flags.len.uint16
  self.flags[i]
