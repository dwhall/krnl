## Copyright 2026 Dean Hall See LICENSE for details
##
## KRNL interface: Effects
##

##   PrivilegedModeEffect indicates a proc that requires the core running in
##   privileged mode to perform its operations.  Applications should NOT run
##   in privileged mode, so an EventHandler may declares
##   `{.forbids: [PrivilegedModeEffect].}` to have the compiler check that it
##   does not call any procs that require privileged mode.
type PrivilegedModeEffect* = object of RootEffect
