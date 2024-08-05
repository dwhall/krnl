#!fmt: off
#
# arm_cm.nim - ARM Cortex-M register and field definitions needed by KRNL
#
# I could find no SVD file for just the common Cortex-M peripherals and registers
# so I created this file using information from the
#
#       Arm v7-M Architecture Reference Manual
#       ARM DDI 0403E (ID021621).
#
# The templates and macros imported from metagenerator will convert these delcarations
# into register and field setters and getters.
#
# See this [README](https://github.com/dwhall/minisvd2nim?tab=readme-ov-file#how-to-access-the-device)
# for usage.
#

import metagenerator

# Cortex-M processor implementation details.
# Either accept "-D" compile-time definitions,
# or use the default values given here
const fpuPresent* {.booldefine: "fpuPresent".}: bool = false
const nvicPrioBits* {.intdefine: "nvicPrioBits".}: int = 3

declareDevice(deviceName=SomeArmCortexM, mpuPresent=true, fpuPresent=fpuPresent, nvicPrioBits=nvicPrioBits)

## NVIC
declarePeripheral(peripheralName=NVIC, baseAddress=0xE000E000'u32, peripheralDesc="Nested Vectored Interrupt Controller")

declareRegister(peripheralName=NVIC, registerName=ISER0, addressOffset=0x100'u32, readAccess=true, writeAccess=true, registerDesc="IRQ 0 to 31 Set-Enable Register")
declareField(peripheralName=NVIC, registerName=ISER0, fieldName=SETENA, bitOffset=0, bitWidth=32, readAccess=true, writeAccess=true, fieldDesc="Enables, or reads the enable state of a group of interrupts")
declareRegister(peripheralName=NVIC, registerName=ISER1, addressOffset=0x104'u32, readAccess=true, writeAccess=true, registerDesc="IRQ 32 to 63 Set-Enable Register")
declareField(peripheralName=NVIC, registerName=ISER1, fieldName=SETENA, bitOffset=0, bitWidth=32, readAccess=true, writeAccess=true, fieldDesc="Enables, or reads the enable state of a group of interrupts")
declareRegister(peripheralName=NVIC, registerName=ISER2, addressOffset=0x108'u32, readAccess=true, writeAccess=true, registerDesc="IRQ 64 to 95 Set-Enable Register")
declareField(peripheralName=NVIC, registerName=ISER2, fieldName=SETENA, bitOffset=0, bitWidth=32, readAccess=true, writeAccess=true, fieldDesc="Enables, or reads the enable state of a group of interrupts")
declareRegister(peripheralName=NVIC, registerName=ISER3, addressOffset=0x10C'u32, readAccess=true, writeAccess=true, registerDesc="IRQ 96 to 127 Set-Enable Register")
declareField(peripheralName=NVIC, registerName=ISER3, fieldName=SETENA, bitOffset=0, bitWidth=32, readAccess=true, writeAccess=true, fieldDesc="Enables, or reads the enable state of a group of interrupts")

declareRegister(peripheralName=NVIC, registerName=ISPR0, addressOffset=0x200'u32, readAccess=true, writeAccess=true, registerDesc="IRQ 0 to 31 Set Pending Register")
declareField(peripheralName=NVIC, registerName=ISPR0, fieldName=SETPEND, bitOffset=0, bitWidth=32, readAccess=true, writeAccess=true, fieldDesc="Sets pending, or reads the pending state of a group of itnerrupts")
declareRegister(peripheralName=NVIC, registerName=ISPR1, addressOffset=0x204'u32, readAccess=true, writeAccess=true, registerDesc="IRQ 0 to 31 Set Pending Register")
declareField(peripheralName=NVIC, registerName=ISPR1, fieldName=SETPEND, bitOffset=0, bitWidth=32, readAccess=true, writeAccess=true, fieldDesc="Sets pending, or reads the pending state of a group of itnerrupts")
declareRegister(peripheralName=NVIC, registerName=ISPR2, addressOffset=0x208'u32, readAccess=true, writeAccess=true, registerDesc="IRQ 0 to 31 Set Pending Register")
declareField(peripheralName=NVIC, registerName=ISPR2, fieldName=SETPEND, bitOffset=0, bitWidth=32, readAccess=true, writeAccess=true, fieldDesc="Sets pending, or reads the pending state of a group of itnerrupts")
declareRegister(peripheralName=NVIC, registerName=ISPR3, addressOffset=0x20C'u32, readAccess=true, writeAccess=true, registerDesc="IRQ 0 to 31 Set Pending Register")
declareField(peripheralName=NVIC, registerName=ISPR3, fieldName=SETPEND, bitOffset=0, bitWidth=32, readAccess=true, writeAccess=true, fieldDesc="Sets pending, or reads the pending state of a group of itnerrupts")

declareRegister(peripheralName=NVIC, registerName=IPR0, addressOffset=0x400'u32, readAccess=true, writeAccess=true, registerDesc="IRQ 0 to 31 Interrupt Priority Register")
declareField(peripheralName=NVIC, registerName=IPR0, fieldName=PRI_N0, bitOffset=0, bitWidth=8, readAccess=true, writeAccess=true, fieldDesc="Sets or reads interrupt priorities")
declareField(peripheralName=NVIC, registerName=IPR0, fieldName=PRI_N1, bitOffset=8, bitWidth=8, readAccess=true, writeAccess=true, fieldDesc="Sets or reads interrupt priorities")
declareField(peripheralName=NVIC, registerName=IPR0, fieldName=PRI_N2, bitOffset=16, bitWidth=8, readAccess=true, writeAccess=true, fieldDesc="Sets or reads interrupt priorities")
declareField(peripheralName=NVIC, registerName=IPR0, fieldName=PRI_N3, bitOffset=24, bitWidth=8, readAccess=true, writeAccess=true, fieldDesc="Sets or reads interrupt priorities")

declareRegister(peripheralName=NVIC, registerName=IPR1, addressOffset=0x404'u32, readAccess=true, writeAccess=true, registerDesc="IRQ 32 to 63 Interrupt Priority Register")
declareField(peripheralName=NVIC, registerName=IPR1, fieldName=PRI_N0, bitOffset=0, bitWidth=8, readAccess=true, writeAccess=true, fieldDesc="Sets or reads interrupt priorities")
declareField(peripheralName=NVIC, registerName=IPR1, fieldName=PRI_N1, bitOffset=8, bitWidth=8, readAccess=true, writeAccess=true, fieldDesc="Sets or reads interrupt priorities")
declareField(peripheralName=NVIC, registerName=IPR1, fieldName=PRI_N2, bitOffset=16, bitWidth=8, readAccess=true, writeAccess=true, fieldDesc="Sets or reads interrupt priorities")
declareField(peripheralName=NVIC, registerName=IPR1, fieldName=PRI_N3, bitOffset=24, bitWidth=8, readAccess=true, writeAccess=true, fieldDesc="Sets or reads interrupt priorities")

## SCB
declarePeripheral(peripheralName=SCB, baseAddress=0xE000ED00'u32, peripheralDesc="System Control Block")
declareRegister(peripheralName=SCB, registerName=AIRCR, addressOffset=0x0C'u32, readAccess=true, writeAccess=true, registerDesc="Application Interrupt and Reset Control Register")
declareField(peripheralName=SCB, registerName=AIRCR, fieldName=VECTRESET, bitOffset=0, bitWidth=1, readAccess=true, writeAccess=true, fieldDesc="Writing 1 to this bit causes a local system reset")
declareField(peripheralName=SCB, registerName=AIRCR, fieldName=VECTCLRACTIVE, bitOffset=1, bitWidth=1, readAccess=true, writeAccess=true, fieldDesc="Writing 1 to this bit clears all active state information for fixed and configurable exceptions")
declareField(peripheralName=SCB, registerName=AIRCR, fieldName=SYSRESETREQ, bitOffset=2, bitWidth=1, readAccess=true, writeAccess=true, fieldDesc="System Reset Request")
declareField(peripheralName=SCB, registerName=AIRCR, fieldName=PRIGROUP, bitOffset=8, bitWidth=3, readAccess=true, writeAccess=true, fieldDesc="Priority grouping, indicates the binary point position")
declareField(peripheralName=SCB, registerName=AIRCR, fieldName=ENDIANNESS, bitOffset=15, bitWidth=1, readAccess=true, writeAccess=false, fieldDesc="Indicates the memory system endianness. 0: Little, 1: Big")
declareField(peripheralName=SCB, registerName=AIRCR, fieldName=VECTKEY, bitOffset=16, bitWidth=16, readAccess=true, writeAccess=true, fieldDesc="Vector Key. Register writes must write 0x05FA to this field, otherwise the write is ignored.")

#declareRegister(peripheralName=SCB, registerName=CCR, addressOffset=0x14'u32, readAccess=true, writeAccess=true, registerDesc="Configuration Control Register")

declareRegister(peripheralName=SCB, registerName=SHPR3, addressOffset=0x20'u32, readAccess=true, writeAccess=true, registerDesc="System Handlers 12-15 Priority Register")
declareField(peripheralName=SCB, registerName=SHPR3, fieldName=PRI_12, bitOffset=0, bitWidth=8, readAccess=true, writeAccess=true, fieldDesc="Priority of system handler 12, DebugMonitor")
declareField(peripheralName=SCB, registerName=SHPR3, fieldName=PRI_13, bitOffset=8, bitWidth=8, readAccess=true, writeAccess=true, fieldDesc="Reserved for priority of system handler 13")
declareField(peripheralName=SCB, registerName=SHPR3, fieldName=PRI_14, bitOffset=16, bitWidth=8, readAccess=true, writeAccess=true, fieldDesc="Priority of system handler 14, PendSV")
declareField(peripheralName=SCB, registerName=SHPR3, fieldName=PRI_15, bitOffset=24, bitWidth=8, readAccess=true, writeAccess=true, fieldDesc="Priority of system handler 15, SysTick")

when fpuPresent:
  ## SCB (cont'd)
  declareRegister(peripheralName=SCB, registerName=FPCCR, addressOffset=0x34'u32, readAccess=true, writeAccess=true, registerDesc="FPU Context Control Register")
  declareField(peripheralName=SCB, registerName=FPCCR, fieldName=LSPEN, bitOffset=30, bitWidth=1, readAccess=true, writeAccess=true, fieldDesc="Enables lazy context save of FP state")
  declareField(peripheralName=SCB, registerName=FPCCR, fieldName=ASPEN, bitOffset=31, bitWidth=1, readAccess=true, writeAccess=true, fieldDesc="Executing an FP instruction sets CONTROL.FPCA to 1")

  declarePeripheral(peripheralName=FPU, baseAddress=0xE000EF00'u32, peripheralDesc="Floating Point Unit (FPU)")
