## Copyright 2026 Dean Hall See LICENSE for details
##
## KRNL: Top level types
##
## This module helps avoid circular dependencies
## and should have no imports of its own.
##

type
  PrivilegedModeEffect* = object of RootEffect
