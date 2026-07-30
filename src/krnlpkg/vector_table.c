/*
Reference:
    https://developer.arm.com/documentation/ddi0403/latest
    DDI0403E_e_armv7m_arm.pdf
    B1.5 Armv7-M exception model
*/

#include <stdint.h>

typedef void (*ExceptionHandler)(void);
typedef void (*ExternalIrqHandler)(void);
typedef struct
{                                       /* Exception Number */
    uint32_t *stackPointer;             /* 0      */
    ExceptionHandler exception[15];     /* 1..15  */
    ExternalIrqHandler externalIrq[48]; /* 16..63 */
} VectorTable;

/* A reserved exception should never happened */
static void reserved_Handler(void) {
    /* Stay here so a debugger will reveal the problem */
    for(;;);
}

/* These functions are aliased to default_Handler in nrf52.ld
   and may be overridden in nim as needed.
   Be sure to use the pragma: {.exportc, noconv.}
*/
void Reset_Handler(void);
void NMI_Handler(void);
void HardFault_Handler(void);
void MemoryManagement_Handler(void);
void BusFault_Handler(void);
void UsageFault_Handler(void);
void SVC_Handler(void);
void DebugMon_Handler(void);
void PendSV_Handler(void);
void SysTick_Handler(void);
void POWER_CLOCK_IRQHandler(void);
void RADIO_IRQHandler(void);
void UARTE0_UART0_IRQHandler(void);
void SPIM0_SPIS0_TWIM0_TWIS0_SPI0_TWI0_IRQHandler(void);
void SPIM1_SPIS1_TWIM1_TWIS1_SPI1_TWI1_IRQHandler(void);
void NFCT_IRQHandler(void);
void GPIOTE_IRQHandler(void);
void SAADC_IRQHandler(void);
void TIMER0_IRQHandler(void);
void TIMER1_IRQHandler(void);
void TIMER2_IRQHandler(void);
void RTC0_IRQHandler(void);
void TEMP_IRQHandler(void);
void RNG_IRQHandler(void);
void ECB_IRQHandler(void);
void CCM_AAR_IRQHandler(void);
void WDT_IRQHandler(void);
void RTC1_IRQHandler(void);
void QDEC_IRQHandler(void);
void COMP_LPCOMP_IRQHandler(void);
void SWI0_EGU0_IRQHandler(void);
void SWI1_EGU1_IRQHandler(void);
void SWI2_EGU2_IRQHandler(void);
void SWI3_EGU3_IRQHandler(void);
void SWI4_EGU4_IRQHandler(void);
void SWI5_EGU5_IRQHandler(void);
void TIMER3_IRQHandler(void);
void TIMER4_IRQHandler(void);
void PWM0_IRQHandler(void);
void PDM_IRQHandler(void);
void ACL_NVMC_IRQHandler(void);
void PPI_IRQHandler(void);
void MWU_IRQHandler(void);
void PWM1_IRQHandler(void);
void PWM2_IRQHandler(void);
void SPIM2_SPIS2_SPI2_IRQHandler(void);
void RTC2_IRQHandler(void);
void I2S_IRQHandler(void);
void FPU_IRQHandler(void);
void USBD_IRQHandler(void);
void UARTE1_IRQHandler(void);
void QSPI_IRQHandler(void);
void CRYPTOCELL_IRQHandler(void);
void CRYPTOCELL_ENG_IRQHandler(void);
void RESERVED44_IRQHandler(void);
void PWM3_IRQHandler(void);
void RESERVED46_IRQHandler(void);
void SPIM3_IRQHandler(void);

/* The linker script provides this symbol.  The stack is located at or
   near the greatest-valued address in RAM and grows toward lesser values.
*/
extern uint32_t __StackTop;

/* The section attribute locates the vector table at the linker symbol, .isr_vector
   The used attribute prevents the optimizer from removing this struct
   that is not referred to by any other variable.
*/
VectorTable const vectorTable __attribute__((section(".isr_vector"), used)) = {
    .stackPointer = &__StackTop,
    .exception = {
        Reset_Handler,
        NMI_Handler,
        HardFault_Handler,
        MemoryManagement_Handler,
        BusFault_Handler,
        UsageFault_Handler,
        reserved_Handler,
        reserved_Handler,
        reserved_Handler,
        reserved_Handler,
        SVC_Handler,
        DebugMon_Handler,
        reserved_Handler,
        PendSV_Handler,
        SysTick_Handler,
    },
    .externalIrq = { /* Interrupt Number */
        POWER_CLOCK_IRQHandler, /* 0 */
        RADIO_IRQHandler,
        UARTE0_UART0_IRQHandler,
        SPIM0_SPIS0_TWIM0_TWIS0_SPI0_TWI0_IRQHandler,
        SPIM1_SPIS1_TWIM1_TWIS1_SPI1_TWI1_IRQHandler,
        NFCT_IRQHandler, /* 5 */
        GPIOTE_IRQHandler,
        SAADC_IRQHandler,
        TIMER0_IRQHandler,
        TIMER1_IRQHandler,
        TIMER2_IRQHandler, /* 10 */
        RTC0_IRQHandler,
        TEMP_IRQHandler,
        RNG_IRQHandler,
        ECB_IRQHandler,
        CCM_AAR_IRQHandler, /* 15 */
        WDT_IRQHandler,
        RTC1_IRQHandler,
        QDEC_IRQHandler,
        COMP_LPCOMP_IRQHandler,
        SWI0_EGU0_IRQHandler, /* 20 */
        SWI1_EGU1_IRQHandler,
        SWI2_EGU2_IRQHandler,
        SWI3_EGU3_IRQHandler,
        SWI4_EGU4_IRQHandler,
        SWI5_EGU5_IRQHandler, /* 25 */
        TIMER3_IRQHandler,
        TIMER4_IRQHandler,
        PWM0_IRQHandler,
        PDM_IRQHandler,
        ACL_NVMC_IRQHandler, /* 30 */
        PPI_IRQHandler,
        MWU_IRQHandler,
        PWM1_IRQHandler,
        PWM2_IRQHandler,
        SPIM2_SPIS2_SPI2_IRQHandler, /* 35 */
        RTC2_IRQHandler,
        I2S_IRQHandler,
        FPU_IRQHandler,
        USBD_IRQHandler,
        UARTE1_IRQHandler, /* 40 */
        QSPI_IRQHandler,
        CRYPTOCELL_IRQHandler,
        CRYPTOCELL_ENG_IRQHandler,
        reserved_Handler,
        PWM3_IRQHandler, /* 45 */
        reserved_Handler,
        SPIM3_IRQHandler, /* 47 */
    },
};
