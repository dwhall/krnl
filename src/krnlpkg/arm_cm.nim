# arm_cm.nim

import ./templates
#import minisvd2nimpkg/templates

#[
#define NVIC_EN      ((uint32_t volatile *)0xE000E100U)
        NVIC_EN[me->nvic_irq >> 5U] = (1U << (me->nvic_irq & 0x1FU));

#define NVIC_PEND    ((uint32_t volatile *)0xE000E200U)
        me->nvic_pend = &NVIC_PEND[me->nvic_irq >> 5U];

#define NVIC_IP      ((uint32_t volatile *)0xE000E400U)
        NVIC_IP[me->nvic_irq >> 2U] = tmp;

#define SCB_AIRCR   *((uint32_t volatile *)0xE000ED0CU)
        SCB_AIRCR = (0x05FAU << 16U) | tmp;

#define SCB_SYSPRI   ((uint32_t volatile *)0xE000ED14U)     # ? CCR
 usage: SCB_SYSPRI[3] = 0xE000ED14U
                           + 3 * 4
                           =========
                           0xE000ED20'u == SH3PR

#define FPU_FPCCR   *((uint32_t volatile *)0xE000EF34U)
        FPU_FPCCR |= (1U << 30U)    /* automatic FPU state preservation (ASPEN) */
                   | (1U << 31U); /* lazy stacking (LSPEN) */
]#

# Allow compile-time definition of these Cortex-M implementation-defined values
const fpuPresent {.booldefine: "fpuPresent".}: bool = false
const nvicPrioBits {.intdefine: "nvicPrioBits".}: int = 3

declareDevice(SomeArmCortexM, true, fpuPresent, nvicPrioBits)
declarePeripheral(NVIC, 0xE000E000'u32, "Nested Vectored Interrupt Controller (NVIC)")
declareRegister(NVIC, EN, 0x100'u32, true, true, "IRQ 0 to 31 Set Enable Register")
declareRegister(NVIC, PEND, 0x200'u32, true, true, "IRQ 0 to 31 Set Pending Register")
declareRegister(NVIC, IP, 0x400'u32, true, true, "IRQ 0 to 31 Interrupt Priority Register")
declareRegister(NVIC, AIRCR, 0xD0C'u32, true, true, "Application Interrupt/Reset Control Register")
#declareRegister(NVIC, CCR, 0xD14'u32, true, true, "Configuration Control Register")
declareRegister(NVIC, SH3PR#[madeup regnam]#, 0xD20'u32, true, true, "System Handlers 12-15 Priority Register")

declarePeripheral(FPU, 0xE000EF00'u32, "Floating Point Unit (FPU)")
declareRegister(FPU, FPCCR, 0x34'u32, false, true, "FPU Config Control Register")
