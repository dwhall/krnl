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
    assert sigEnum < 256
  else:
    assert sigEnum < 1024
  const
    hashMask = when kind == SigShort: 0x7FFFFF00'u32 else: 0x7FFFFC00'u32
    truncatedHash = locator.hash.uint32 and hashMask
    sigIdxMask = when kind == SigShort: 0xFF'u32 else: 0x3FF'u32
    sigKindBit =
      when kind == SigShort:
        0'u32
      else:
        1'u32 shl 31
  assert sigEnum <= sigIdxMask
  Signal(sigKindBit or truncatedHash or sigEnum)

func Sig*(
    dottedLocator: static string,
    sigEnum: static uint32,
    kind: static SignalKind = SigShort,
): Signal {.compileTime.} =
  const locator = toSourceLocator(dottedLocator)
  Sig(locator, sigEnum, kind)
