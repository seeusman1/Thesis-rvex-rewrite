/* Debug interface for standalone r-VEX processor
 * 
 * Copyright (C) 2008-2016 by TU Delft.
 * All Rights Reserved.
 * 
 * THIS IS A LEGAL DOCUMENT, BY USING r-VEX,
 * YOU ARE AGREEING TO THESE TERMS AND CONDITIONS.
 * 
 * No portion of this work may be used by any commercial entity, or for any
 * commercial purpose, without the prior, written permission of TU Delft.
 * Nonprofit and noncommercial use is permitted as described below.
 * 
 * 1. r-VEX is provided AS IS, with no warranty of any kind, express
 * or implied. The user of the code accepts full responsibility for the
 * application of the code and the use of any results.
 * 
 * 2. Nonprofit and noncommercial use is encouraged. r-VEX may be
 * downloaded, compiled, synthesized, copied, and modified solely for nonprofit,
 * educational, noncommercial research, and noncommercial scholarship
 * purposes provided that this notice in its entirety accompanies all copies.
 * Copies of the modified software can be delivered to persons who use it
 * solely for nonprofit, educational, noncommercial research, and
 * noncommercial scholarship purposes provided that this notice in its
 * entirety accompanies all copies.
 * 
 * 3. ALL COMMERCIAL USE, AND ALL USE BY FOR PROFIT ENTITIES, IS EXPRESSLY
 * PROHIBITED WITHOUT A LICENSE FROM TU Delft (J.S.S.M.Wong@tudelft.nl).
 * 
 * 4. No nonprofit user may place any restrictions on the use of this software,
 * including as modified by the user, by any other authorized user.
 * 
 * 5. Noncommercial and nonprofit users may distribute copies of r-VEX
 * in compiled or binary form as set forth in Section 2, provided that
 * either: (A) it is accompanied by the corresponding machine-readable source
 * code, or (B) it is accompanied by a written offer, with no time limit, to
 * give anyone a machine-readable copy of the corresponding source code in
 * return for reimbursement of the cost of distribution. This written offer
 * must permit verbatim duplication by anyone, or (C) it is distributed by
 * someone who received only the executable form, and is accompanied by a
 * copy of the written offer of source code.
 * 
 * 6. r-VEX was developed by Stephan Wong, Thijs van As, Fakhar Anjam,
 * Roel Seedorf, Anthony Brandon, Jeroen van Straten. r-VEX is currently
 * maintained by TU Delft (J.S.S.M.Wong@tudelft.nl).
 * 
 * Copyright (C) 2008-2016 by TU Delft.
 */

#include "pcie.h"

#include "../main.h"
#include "../rvex_iface.h"
#include "../tcpserv.h"

#include <fcntl.h>
#include <unistd.h>

#include <stdio.h>
#include <stdlib.h>

/**
 * File descriptor of the rVEX memory character device.
 */
static int cdev_fd = -1;


/**
 * Tries to handle a Read or Write command sent by a TCP client connected to
 * the debug server. command should be null-terminated.
 */
static int pcie_read(uint32_t address, uint32_t buf_size, int clientID) {
  /* Allocate buffer */
  unsigned char *buffer = malloc(buf_size);
  if (!buffer) {
    perror("pcie_read: Failed to allocate memory to service debug read command");
    return -1;
  }

  /* Seek to address */
  off_t off = lseek (cdev_fd, address, SEEK_SET);
  if (off == (off_t)-1) {
    perror("pcie_read: Failed to seek to address");
    free(buffer);
    return -1;
  }

  /* Read data into buffer */
  unsigned char *bufp = buffer;
  uint32_t bytes_left = buf_size;
  while(bytes_left > 0) {
    ssize_t bytes_read = read(cdev_fd, bufp, buf_size);
    if(bytes_read == -1) {
      perror("pcie_read: Failed to read bytes");
      free(buffer);
      return -1;
    }

    bufp += bytes_read;
    bytes_left -= bytes_read;
  }

  /* Transmit response to client
   * Note: we don't consider communication errors as fatal errors, so return
   * 0 in case that happens */
  int i;
  unsigned char str[32];
  /* Send status, we don't check for read failures */
  if (tcpServer_sendStr(debugServer, clientID, (const unsigned char *)("OK, Read, OK, ")) < 0) {
    free(buffer);
    return 0;
  }
  /* Send read arguments */
  sprintf((char *)str, "%08X, %d, ", address, buf_size);
  if (tcpServer_sendStr(debugServer, clientID, str) < 0) {
    free(buffer);
    return 0;
  }
  /* Send read bytes */
  for (i = 0; i < buf_size; i++) {
    sprintf((char *)str, "%02hhX", buffer[i]);
    if (tcpServer_sendStr(debugServer, clientID, str) < 0) {
      free(buffer);
      return 0;
    }
  }
  /* Terminate response */
  if (tcpServer_sendStr(debugServer, clientID, (const unsigned char *)";\n") < 0) {
    free(buffer);
    return 0;
  }

  free(buffer);
  return 0;
}

/**
 * Tries to handle a Read or Write command sent by a TCP client connected to
 * the debug server. command should be null-terminated.
 */
static int pcie_write(uint32_t address, unsigned char *buffer,
    uint32_t buf_size, int clientID) {
  /* Seek to address */
  off_t off = lseek (cdev_fd, address, SEEK_SET);
  if (off == (off_t)-1) {
    perror("pcie_write: Failed to seek to address");
    return -1;
  }

  /* Read data into buffer */
  unsigned char *bufp = buffer;
  while(buf_size > 0) {
    ssize_t bytes_written = write(cdev_fd, bufp, buf_size);
    if(bytes_written == -1) {
      perror("pcie_write: Failed to write bytes");
      return -1;
    }

    bufp += bytes_written;
    buf_size -= bytes_written;
  }

  /* Transmit response to client */
  /* Note: we don't consider communication errors as fatal errors, so return
   * 0 in case that happens */
  unsigned char str[32];
  /* Send status, we don't check for write failures */
  if (tcpServer_sendStr(debugServer, clientID, (const unsigned char *)("OK, Write, OK, ")) < 0) {
    return 0;
  }
  /* Send write arguments and terminate response */
  sprintf((char *)str, "%08X, %d;\n", address, buf_size);
  if (tcpServer_sendStr(debugServer, clientID, str) < 0) {
    return 0;
  }

  return 0;
}

/**
 * Updates the backend. Returns -1 if an error occured, 0 if the system is
 * idle, or 1 if we want update to be called quickly again to handle potential
 * timeouts.
 */
int pcie_update(void) {
  /* This backend doesn't to update anything as all calls are blocking */
  return 0;
}

/**
 * Frees all dynamically allocated memory by the interface.
 */
void pcie_free(void) {
  close(cdev_fd);

  cdev_fd = -1;
}

int init_pcie_iface(const char *cdev, rvex_iface_t *iface) {
  cdev_fd = open(cdev, O_RDWR);
  if (cdev_fd < 0) {
    perror("init_pcie_iface: Couldn't open character device");
    return -1;
  }

  printf("Successfully opened character device \"%s\"\n.", cdev);

  *iface = (rvex_iface_t) {
    .read = pcie_read,
    .write = pcie_write,
    .update = pcie_update,
    .free = pcie_free,
  };

  return 0;
}
