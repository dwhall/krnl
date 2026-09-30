## Copyright 2026 Dean Hall See LICENSE for details
##
## KRNL Signal

import std/strutils
import namespace

type
  ## A Signal is a value that discriminates an Event.
  Signal* = uint32

  SignalKind* = enum
    SigShort = 0 # 23-bit signal identity, 8-bit enumerator
    SigLong = 1 # 21-bit signal identity, 10-bit enumerator

  SigSeries* = tuple[nsHash: NamespaceHash32, sig: uint32]

func Sig*(
    dottedNames: static string,
    sigEnum: static uint32,
    kind: static SignalKind = SigShort,
): Signal {.compileTime.} =
  ## Composes a signal from the dotted namespace (case insensitive) and signal enum.
  when kind == SigShort:
    const
      sigIdentMask = 0x7FFF_FF00'u32
      sigEnumMask = 0xFF'u32
  else:
    const
      sigIdentMask = 0x7FFF_FC00'u32
      sigEnumMask = 0x3FF'u32
  assert sigEnum <= sigEnumMask, "sigEnum exceeds bitfield limit"
  assert dottedNames.count('.') == 2
  const
    nsHash = NS32(dottedNames)
    sigIdent =
      (kind.uint32 shl 31) or (nsHash.uint32 and sigIdentMask) or
      (sigEnum and sigEnumMask)
  Signal(sigIdent)

# TODO: await clarification on (dottednames, sig) vs (nsHash, sig)
# converter toSignal*(sigTuple: SigSeries): Signal =
#   ## Converts a SigSeries to a Signal
#   Sig(sigTuple.nsHash.uint32 or sigTuple.sig)
