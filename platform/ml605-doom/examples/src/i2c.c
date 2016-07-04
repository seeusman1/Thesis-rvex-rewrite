#include "i2c.h"
#include "rvex.h"

#if 0
// Command masks.
#define STA   0x80
#define STO   0x40
#define RD    0x20
#define WR    0x10
#define ACK   0x08

// Status masks.
#define RXACK 0x80
#define TIP   0x02

// Wait for transfer complete.
#define WAIT  while (p->cmdstat & TIP)

/**
 * Initializes an I2C peripheral.
 */
int i2c_init(volatile i2cmst_t *p) {
  p->prescale = 0x100;
  p->ctrl = 0x80;
}

// Starts an I2C transfer.
static int start(volatile i2cmst_t *p, int addr) {
  
  //puts("S");
  
  // Send slave address.
  p->data = addr;
  p->cmdstat = STA | WR;
  WAIT;
  
  // Read acknowledgement.
  if (p->cmdstat & RXACK) {
    // This writes a dummy byte to a non-responsive slave. Don't know what else
    // to do, the manual doesn't specify.
    p->data = 0;
    p->cmdstat = STO | WR;
    WAIT;
    //puts("?");
    return -1;
  }
  
  //puts("!");
  return 0;
}

// Writes a byte. If last is nonzero, this will be the last transfer.
static int writ(volatile i2cmst_t *p, int data, int last) {
  
  // Send data.
  p->data = data;
  if (last) {
    p->cmdstat = WR | STO;
  } else {
    p->cmdstat = WR;
  }
  WAIT;
  
  // Read acknowledgement.
  if (p->cmdstat & RXACK) {
    if (!last) {
      // This writes a dummy byte to a non-responsive slave. Don't know what else
      // to do, the manual doesn't specify.
      p->data = 0;
      p->cmdstat = STO | WR;
      WAIT;
    }
    return -1;
  }
  
  return 0;
}

// Reads a byte. If last is nonzero, this will be the last transfer.
static int rea(volatile i2cmst_t *p, int last) {
  
  // Read data.
  if (last) {
    p->cmdstat = RD | ACK | STO;
  } else {
    p->cmdstat = RD;
  }
  WAIT;
  return p->data;
  
}

/**
 * Writes to an I2C device (blocking).
 *  - p must be set to the I2C peripheral address.
 *  - addr is the 7-bit I2C address (in bit 6..0).
 *  - reg is the I2C device register offset (first byte that is sent).
 *  - data and count specify the values to be written (second and later bytes).
 * Returns 0 if successful or -1 if the slave did not acknowledge somthing.
 */
int i2c_write(volatile i2cmst_t *p, int addr, int reg, const char *data, int count) {
  
  // Make sure the peripheral is initialized.
  p->ctrl = 0x00;
  p->prescale = 400;
  p->ctrl = 0x80;
  
  // Start the transfer.
  if (start(p, addr << 1)) return -1;
  
  // Send the register address.
  if (writ(p, reg, count==0)) return -1;
  
  // Send the data.
  while (count--) {
    if (writ(p, *data++, count==0)) return -1;
  }
  
  return 0;
  
}

/**
 * Reads from an I2C device (blocking).
 *  - p must be set to the I2C peripheral address.
 *  - addr is the 7-bit I2C address (in bit 6..0).
 *  - reg is the I2C device register offset.
 *  - data and count specify the values to be read.
 * Returns 0 if successful or -1 if the slave did not acknowledge somthing.
 */
int i2c_read(volatile i2cmst_t *p, int addr, int reg, char *data, int count) {
  
  // Make sure the peripheral is initialized.
  p->ctrl = 0x00;
  p->prescale = 400;
  p->ctrl = 0x80;
  
  // Start the transfer.
  if (start(p, addr << 1)) return -1;
  
  // Send the register address.
  if (writ(p, reg, 0)) return -1;
  
  // Repeated start for the read.
  if (start(p, (addr << 1) | 1)) return -1;
  
  // Read the data.
  while (count--) {
    *data++ = (char)rea(p, count==0);
  }
  
}

#else

/*
 * Test for I2CMST
 *
 * Copyright (c) 2009 Aeroflex Gaisler AB
 *
 * This test application transfers data between an I2CMST core
 * and an I2CSLV core. The transfers are _not_ interrupt driven.
 *
 * This application assumes that the I2CSLV's address is programmable. 
 *
 */

/* Register fields for I2CMST */
/* Control register */
#define I2CMST_CTR_EN   (1 << 7)   /* Enable core */
#define I2CMST_CTR_IEN  (1 << 6)   /* Interrupt enable */
/* Command register */
#define I2CMST_CR_STA   (1 << 7)   /* Generate start condition */
#define I2CMST_CR_STO   (1 << 6)   /* Generate stop condition */
#define I2CMST_CR_RD    (1 << 5)   /* Read from slave */
#define I2CMST_CR_WR    (1 << 4)   /* Write to slave */
#define I2CMST_CR_ACK   (1 << 3)   /* ACK, when a receiver send ACK (ACK = 0) 
                                      or NACK (ACK = 1) */
#define I2CMST_CR_IACK  (1 << 0)   /* Interrupt acknowledge */
/* Status register */
#define I2CMST_SR_RXACK (1 << 7)   /* Receibed acknowledge from slave */
#define I2CMST_SR_BUSY  (1 << 6)   /* I2C bus busy */
#define I2CMST_SR_AL    (1 << 5)   /* Arbitration lost */
#define I2CMST_SR_TIP   (1 << 1)   /* Transfer in progress */
#define I2CMST_SR_IF    (1 << 0)   /* Interrupt flag */

/* I2CMST registers */
struct i2cmst_regs {
   volatile unsigned int prer;
   volatile unsigned int ctr;
   volatile unsigned int xr;
   volatile unsigned int csr;
};


/* Test configuration */
#define PRESCALER   0x0041


int i2c_init(volatile i2cmst_t *p) {
}

int i2c_read(volatile i2cmst_t *p, int addr, int reg, char *data, int count)
{
   int i;
   struct i2cmst_regs *mstregs;


   mstregs = (struct i2cmst_regs*)p;

   /* Initialize and enable I2CMST */
   mstregs->prer = PRESCALER;

   /* Enable core */
   mstregs->ctr = I2CMST_CTR_EN;
  
   /* Write address and read bit into transmit register */
   mstregs->xr = (addr << 1) | 0;
   
   /* Set STA and WR */
   mstregs->csr = I2CMST_CR_STA | I2CMST_CR_WR;
  
   /* Wait for TIP to go low */
   while (mstregs->csr & I2CMST_SR_TIP)
      ;
      
      /* Check RxACK bit */
   if (mstregs->csr & I2CMST_SR_RXACK) {
      return -1;
   }
   
   /* Write address to transmit register */
   mstregs->xr = reg;
   mstregs->csr = I2CMST_CR_WR;
   
   /* Wait for TIP to go low */
   while (mstregs->csr & I2CMST_SR_TIP)
      ;

   /* Check RxACK bit */
   if (mstregs->csr & I2CMST_SR_RXACK) {
      return -1;
   }
   
   /* Write address and read bit into transmit register */
   mstregs->xr = (addr << 1) | 1;
   
   /* Set STA and WR */
   mstregs->csr = I2CMST_CR_STA | I2CMST_CR_WR;
  
   /* Wait for TIP to go low */
   while (mstregs->csr & I2CMST_SR_TIP)
      ;
      
      /* Check RxACK bit */
   if (mstregs->csr & I2CMST_SR_RXACK) {
      return -1;
   }

   for (i = 0; i < count; i++) {
      /* Set RD, STO and ACK are set if we are at the last element
         (CR_ACK = 0 to ACK) */
      mstregs->csr = (I2CMST_CR_RD | 
                      (i == count-1 ? I2CMST_CR_STO | I2CMST_CR_ACK : 0));
      
      /* Wait for TIP to go low */
      while (mstregs->csr & I2CMST_SR_TIP)
         ;

      data[i] = mstregs->xr;
   }

   /* Disable core */
//   mstregs->ctr = 0;

   return 0;
}

#endif