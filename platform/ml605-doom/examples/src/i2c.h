#ifndef _I2C_H_
#define _I2C_H_

// GRLIB I2C master peripheral.
typedef struct {
  unsigned int prescale;
  unsigned int ctrl;
  unsigned int data;
  unsigned int cmdstat;
} i2cmst_t;

#define I2C_DVI   ((volatile i2cmst_t*)0x80000700)
#define I2C_PMBUS ((volatile i2cmst_t*)0x80000800)
#define I2C_ZEBRO ((volatile i2cmst_t*)0x80000900)

/**
 * Initializes an I2C peripheral.
 */
int i2c_init(volatile i2cmst_t *p);

/**
 * Writes to an I2C device (blocking).
 *  - p must be set to the I2C peripheral address.
 *  - addr is the 7-bit I2C address (in bit 6..0).
 *  - reg is the I2C device register offset (first byte that is sent).
 *  - data and count specify the values to be written (second and later bytes).
 * Returns 0 if successful or -1 if the slave did not acknowledge somthing.
 */
int i2c_write(volatile i2cmst_t *p, int addr, int reg, const char *data, int count);

/**
 * Reads from an I2C device (blocking).
 *  - p must be set to the I2C peripheral address.
 *  - addr is the 7-bit I2C address (in bit 6..0).
 *  - reg is the I2C device register offset.
 *  - data and count specify the values to be read.
 * Returns 0 if successful or -1 if the slave did not acknowledge somthing.
 */
int i2c_read(volatile i2cmst_t *p, int addr, int reg, char *data, int count);

#endif