## Copyright 2026 Dean Hall See LICENSE for details
##
## A string composed of identifiers joined by dots ('.')
## forms the concept of a namespace.  An example of a dottedString:
##   "domain.package.module"
## We hash the names, not including the dots, with case insensitivity
## to produce a somewhat unique 32- or 64-bit value from the dottedString.
##

import std/[hashes, os, strutils]

const domain {.strdefine.} = ""
static:
  assert domain != "", "domain must be defined by the build."

type
  NamespaceHash32* = uint32

func NS64*(dottedNames: static string): Hash {.compileTime.} =
  ## A compile-time hash of a dotted namespace (case insensitive)
  for name in dottedNames.split('.'):
    result = result !& hashIgnoreCase(name)

func NS32*(dottedNames: static string): NamespaceHash32 {.compileTime.} =
  ## A compile-time hash of a dotted namespace (case insensitive)
  ## This func is intended for use as a string-prefix operator:
  ##    NS32"dom.pkg.mod"
  NamespaceHash32(NS64(dottedNames).uint32)

template NS32*(): NamespaceHash32 =
  # This MUST be a template so it is evaluated in the caller's module
  const module = currentSourcePath().splitPath()[-1].split('.')[0]
  const dottedNames = domain & ".package." & module
  NS32(dottedNames)

# In case we want distinct NamespaceHash32
# proc `==`*(left, right: NamespaceHash32): bool {.borrow.}
# proc `==`*(left: NamespaceHash32, right: uint32): bool {.borrow.}
# proc `==`*(left: uint32, right: NamespaceHash32): bool {.borrow.}
