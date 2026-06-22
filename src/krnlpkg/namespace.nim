## Copyright 2026 Dean Hall See LICENSE for details
##

import std/[hashes, strutils]

type Namespace = object
  ## A Namespace is an identifier that combines with a local identifier
  ## resulting in a new identifier that is sufficiently unique to the needed scope
  ##
  ## The implementation of this type is kept private (opaque) on purpose.  Only the
  ## toNamespace() converter is exported.  This allows us to change the
  ## implementation, if necessary, in the future and the compatibility boundary
  ## is the signature of the toNamespace() coverter.  At this time, Namespaces
  ## are planned for use in Signals and pub-sub Data items.
  domain: string
  package: string
  module: string

converter toNamespace*(dottedNames: static string): Namespace =
  assert dottedNames.count('.') == 2, "Expecting exactly two `.` in dottedNames"
  assert dottedNames.count(' ') == 0, "Expecting no spaces ` ` in dottedNames"
  # TODO: validate as a legit identifier
  const names = dottedNames.split('.')
  Namespace(domain: names[0], package: names[1], module: names[2])

func hash*(namespace: Namespace): Hash {.compileTime.} =
  ## A case-insensitive hash of domain, then package, then module
  hashIgnoreCase(namespace.domain) !& hashIgnoreCase(namespace.package) !&
    hashIgnoreCase(namespace.module)
