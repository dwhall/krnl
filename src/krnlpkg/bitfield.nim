## Copyright 2026 Dean Hall See LICENSE for details
##
## Bitfield datatype for KRNL
##
## This is a simple implementation of a bitfield, which is a set of
## bits in an array of 32-bit fields.  The number of bits in the field is
## determined at compile time by the template parameter N.
##
## We did not use the built-in set datatype because we wished to determine
## the exact bit layout in the fields and to use the fields themselves.

import std/math

type Bitfield*[N: static uint16] = object
  fields: array[ceilDiv(N, 32'u16), uint32]
  card: uint16 # number of bits currently set

proc cap*(self: Bitfield): uint16 =
  self.fields.len.uint16 * 32'u16

proc incl*(self: var Bitfield, flag: uint16) =
  assert flag < self.cap
  let
    (fieldIdx, bitIdx) = divmod(flag, 32'u16)
    alreadySet = flag in self
  if not alreadySet and self.card < self.cap:
    inc self.card
  self.fields[fieldIdx] = self.fields[fieldIdx] or (1'u32 shl bitIdx)

proc excl*(self: var Bitfield, flag: uint16) =
  assert flag < self.cap
  let
    (fieldIdx, bitIdx) = divmod(flag, 32'u16)
    alreadySet = flag in self
  if alreadySet and self.card > 0:
    dec self.card
  self.fields[fieldIdx] = self.fields[fieldIdx] and not (1'u32 shl bitIdx)

proc contains*(self: Bitfield, flag: uint16): bool =
  assert flag < self.cap
  let (fieldIdx, bitIdx) = divmod(flag, 32'u16)
  (self.fields[fieldIdx] and (1'u32 shl bitIdx)) != 0'u32

proc isEmpty*(self: Bitfield): bool =
  self.card == 0

proc `[]`*(self: Bitfield, i: uint8): uint32 =
  ## Returns the i-th 32-bit wide group of flags, where i is in the range [0, N div 32)
  assert i < self.fields.len.uint16
  self.fields[i]
