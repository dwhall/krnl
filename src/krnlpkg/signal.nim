## Copyright 2026 Dean Hall See LICENSE for details
##
## KRNL Signal

import source_locator, types

type SignalKind* = enum
  SigShort = 0 # 23-bit source, 8-bit index
  SigLong = 1 # 21-bit source, 10-bit index

func Sig*(
    locator: static SourceLocator,
    sigEnum: static uint32,
    kind: static SignalKind = SigShort,
): Signal {.compileTime.} =
  ## Composes a signal from the source locator (case insensitive) and signal enum
  when kind == SigShort:
    const
      hashMask = 0x7FFF_FF00'u32
      sigIdxMask = 0xFF'u32
      sigKindBit = 0'u32
  else:
    const
      hashMask = 0x7FFF_FC00'u32
      sigIdxMask = 0x3FF'u32
      sigKindBit = 0x8000_0000'u32
  const truncatedHash = locator.hash.uint32 and hashMask
  assert sigEnum <= sigIdxMask
  Signal(sigKindBit or truncatedHash or sigEnum)

func Sig*(
    dottedLocator: static string,
    sigEnum: static uint32,
    kind: static SignalKind = SigShort,
): Signal {.compileTime.} =
  const locator = toSourceLocator(dottedLocator)
  Sig(locator, sigEnum, kind)
