## Copyright 2026 Dean Hall See LICENSE for details
##
## KRNL Signal

import source_locator, types

type SignalKind* = enum
  SigShort # 23-bit source locator, 8-bit index
  SigLong # 21-bit source locator, 10-bit index

func Sig*(
    dottedLocator: static string,
    sigEnum: static uint32,
    kind: static SignalKind = SigShort,
): Signal {.compileTime.} =
  ## Composes a signal from the dotted source locator (case insensitive) and signal enum,
  ## where the dotted source locator is of the form: `"<domain>.<package>.<module>"`
  when kind == SigShort:
    const
      hashMask = 0x7FFF_FF00'u32
      sigEnumMask = 0xFF'u32
  else:
    const
      hashMask = 0x7FFF_FC00'u32
      sigEnumMask = 0x3FF'u32
  assert sigEnum <= sigEnumMask, "sigEnum exceeds bitfield limit"
  const
    locator = toSourceLocator(dottedLocator)
    truncatedHash = locator.hash.uint32 and hashMask
  Signal((kind.uint32 shl 31) or truncatedHash or (sigEnum and sigEnumMask))
