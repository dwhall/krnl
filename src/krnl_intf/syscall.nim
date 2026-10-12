## Copyright 2026 Dean Hall See LICENSE for details
##
## KRNL interface: System calls
##
## The system calls that application modules may use.
## Importing this module also links krnl_impl/syscall's SVC_Handler,
## which services these calls.
##

import ../krnl_impl/[syscall, syscall_intf]
export syscallPublishEvent, syscallRegisterActr, syscallSubscribe
