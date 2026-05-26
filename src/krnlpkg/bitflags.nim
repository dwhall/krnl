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

type Bitflags*[Nb: static uint16] = object
  flags: array[ceilDiv(Nb, 32'u16), uint32]
  card: uint16 # number of bits currently set

proc cap*(self: Bitflags): uint16 =
  self.flags.len.uint16 * 32'u16

proc incl*(self: var Bitflags, flag: uint16) =
  assert flag < self.cap
  let
    (wordIdx, bitIdx) = divmod(flag, 32'u16)
    alreadySet = flag in self
  if not alreadySet and self.card < self.cap:
    inc self.card
  self.flags[wordIdx] = self.flags[wordIdx] or (1'u32 shl bitIdx)

proc excl*(self: var Bitflags, flag: uint16) =
  assert flag < self.cap
  let
    (wordIdx, bitIdx) = divmod(flag, 32'u16)
    alreadySet = flag in self
  if alreadySet and self.card > 0:
    dec self.card
  self.flags[wordIdx] = self.flags[wordIdx] and not (1'u32 shl bitIdx)

proc contains*(self: Bitflags, flag: uint16): bool =
  assert flag < self.cap
  let (wordIdx, bitIdx) = divmod(flag, 32'u16)
  (self.flags[wordIdx] and (1'u32 shl bitIdx)) != 0'u32

proc isEmpty*(self: Bitflags): bool =
  self.card == 0

proc `[]`*(self: Bitflags, i: uint8): uint32 =
  ## Returns the i-th 32-bit wide group of flags, where i is in the range [0, Nb div 32)
  assert i < self.flags.len.uint16
  self.flags[i]
