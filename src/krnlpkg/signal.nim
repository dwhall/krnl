## Copyright 2026 Dean Hall See LICENSE for details
##
## KRNL Signal

import std/[hashes, strutils]
import types

type SignalKind* = enum
  SigShort = 0 # 23-bit source, 8-bit index
  SigLong = 1 # 21-bit source, 10-bit index

func hash(s: string): uint32 =
  ## Case insensitive hash of a string, truncated to 32 bits.
  hashIgnoreCase(s).uint32

func Sig*(
    domain, module, component: static string,
    sig: static uint16,
    kind: static SignalKind = SigShort,
): Signal {.compileTime.} =
  ## Composes a signal from the module, component, and domain.  Case insensitive.
  when kind is SigShort:
    assert sig < 256'u16
  else:
    assert sig < 1024'u16
  const
    sigSourceHash = hash(domain) xor hash(module) xor hash(component)
    hashMask = when kind == SigShort: 0x7FFFFF00'u32 else: 0x7FFFFC00'u32
    truncatedHash = sigSourceHash and hashMask
    sigIdxMask = when kind == SigShort: 0xFF'u32 else: 0x3FF'u32
    sigKindBit =
      when kind == SigShort:
        0'u32
      else:
        1'u32 shl 31
  assert sig <= sigIdxMask
  Signal(sigKindBit or truncatedHash or sig)

func Sig*(
    dottedSignalSource: static string,
    sig: static uint16,
    kind: static SignalKind = SigShort,
): Signal {.compileTime.} =
  ## Composes a signal from the signal source string.  Case insensitive.
  const sigSource = dottedSignalSource.split('.')
  assert sigSource.len == 3
  Sig(sigSource[0], sigSource[1], sigSource[2], sig, kind)
