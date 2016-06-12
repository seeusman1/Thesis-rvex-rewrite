#ifndef _PLATFORM_H_
#define _PLATFORM_H_

// GRLIB interrupt controller peripheral.
typedef struct {
  unsigned int level;
  unsigned int pending;
  unsigned int RESERVED_A;
  unsigned int clear;
  unsigned int mp_status;
  unsigned int broadcast;
  unsigned int RESERVED_B[10];
  unsigned int mask[16];
  unsigned int force[16];
  unsigned int ext_ack[16];
} irqmp_t;

#define IRQMP ((volatile irqmp_t*)0x80000200)

#define IRQ_TIM1 8

// rVEX debug UART peripheral.
#define UART_BASE 0xD1000000
#define UART_DATA (*((volatile unsigned char *)(UART_BASE)))
#define UART_STAT (*((volatile unsigned char *)(UART_BASE+4)))

// GRLIB general purpose timer peripheral.
typedef struct {
  unsigned int scaler_val;
  unsigned int scaler_reload;
  unsigned int config;
  unsigned int latchsel;
  unsigned int tim1_val;
  unsigned int tim1_reload;
  unsigned int tim1_config;
  unsigned int tim1_latch;
  unsigned int tim2_val;
  unsigned int tim2_reload;
  unsigned int tim2_config;
  unsigned int tim2_latch;
} gptimer_t;

#define TIM1 ((volatile gptimer_t*)0x80000300)

#endif