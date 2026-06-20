## Copyright 2026 Dean Hall See LICENSE for details
##

import std/[hashes, strutils]

type SourceLocator* = object
  ## Pathing information to uniquely identify named source code items
  ## in a large project.  `domain` is the broadest, `package` is the
  ## middle scope, and `module` is the narrowest scope.  SourceLocator
  ## is intended for use with identifying such items as Signals and Data
  domain*: string
  package*: string
  module*: string

converter toSourceLocator*(dottedLocator: static string): SourceLocator =
  assert dottedLocator.count('.') == 2, "Expecting exactly two `.` in dottedLocator"
  assert dottedLocator.count(' ') == 0, "Expecting no spaces ` ` in dottedLocator"
  # TODO: constrain to legit identifier charset
  const sigSource = dottedLocator.split('.')
  SourceLocator(domain: sigSource[0], package: sigSource[1], module: sigSource[2])

func hash*(locator: SourceLocator): Hash {.compileTime.} =
  ## A case-insensitive hash of domain, then package, then module
  hashIgnoreCase(locator.domain) !& hashIgnoreCase(locator.package) !&
    hashIgnoreCase(locator.module)
