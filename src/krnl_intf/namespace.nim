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
  assert domain != "", "domain MUST be defined by the build."

type NamespaceHash32* = distinct uint32

proc `==`*(left, right: NamespaceHash32): bool {.borrow.}
proc hash*(nsHash: NamespaceHash32): Hash {.borrow.}

func NS64(dottedNames: static string): Hash {.compileTime.} =
  ## A compile-time hash of a dotted namespace (case insensitive)
  for name in dottedNames.split('.'):
    # TODO: project-selectable whether hash observes or ignores case?
    result = result !& hashIgnoreCase(name)

func NS32*(dottedNames: static string): NamespaceHash32 {.compileTime.} =
  ## A compile-time hash of a dotted namespace (case insensitive)
  ## This func is intended for use as a string-prefix operator:
  ##    NS32"domain.package.module"
  NamespaceHash32(NS64(dottedNames).uint32)

template NS32*(): NamespaceHash32 =
  ## Uses the defined domain and the caller's filename for the module
  const module = instantiationInfo().filename.splitFile().name
  # TODO: create way to get packageName
  const dottedNames = domain & ".package." & module
  NS32(dottedNames)
