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

#include "mmio.h"

#include "../main.h"
#include "../rvex_iface.h"
#include "../tcpserv.h"

#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/**
 * File descriptor for the memory-mapped file.
 */
static int mmio_fd = -1;

/**
 * Address marking the start offset of the file within memory.
 */
static unsigned char *mmio_addr = NULL;

/**
 * Number of memory-mapped bytes.
 */
static unsigned long mmio_length = 0;

/**
 * Start address of the mmap'd region (i.e. page aligned).
 */
static unsigned char *mmio_map_addr = NULL;

/**
 * Size of the mmap'd region (i.e. page aligned).
 */
static unsigned long mmio_map_length = 0;

/**
 * Tries to handle a Read command sent by a TCP client connected to
 * the debug server.
 */
static int mmio_read(uint32_t address, uint32_t buf_size, int clientID) {
  
  // Make sure that the addresses are not out of the memory-mapped range.
  if ((uint64_t)address + (uint64_t)buf_size > (uint64_t)mmio_length) {
    tcpServer_sendStr(debugServer, clientID, (const unsigned char *)("Error,Read,OutOfMappedRange;\n"));
    return 0;
  }
  
  // Transmit response to client.
  int i;
  unsigned char str[32];
  // Send status, we don't check for read failures.
  if (tcpServer_sendStr(debugServer, clientID, (const unsigned char *)("OK, Read, OK, ")) < 0) {
    return 0;
  }
  // Send read arguments.
  sprintf((char *)str, "%08X, %d, ", address, buf_size);
  if (tcpServer_sendStr(debugServer, clientID, str) < 0) {
    return 0;
  }
  // Send read bytes.
  for (i = 0; i < buf_size; i++) {
    sprintf((char *)str, "%02hhX", mmio_addr[address + i]);
    if (tcpServer_sendStr(debugServer, clientID, str) < 0) {
      return 0;
    }
  }
  // Terminate response.
  if (tcpServer_sendStr(debugServer, clientID, (const unsigned char *)";\n") < 0) {
    return 0;
  }

  return 0;
}

/**
 * Tries to handle a Write command sent by a TCP client connected to
 * the debug server.
 */
static int mmio_write(uint32_t address, unsigned char *buffer,
    uint32_t buf_size, int clientID) {
  
  // Make sure that the addresses are not out of the memory-mapped range.
  if ((uint64_t)address + (uint64_t)buf_size > (uint64_t)mmio_length) {
    tcpServer_sendStr(debugServer, clientID, (const unsigned char *)("Error,Write,OutOfMappedRange;\n"));
    return 0;
  }
  
  // Write the bytes. We want to do word writes when we can, because single byte
  // writes are not supported everywhere.
  unsigned char *ptr = mmio_addr + address;
  unsigned char *buf_ptr = buffer;
  unsigned char *end = mmio_addr + address + buf_size;
  while (ptr < end) {
    if (((long)ptr & 3) || (ptr + 4 > end)) {
      // ptr misaligned or less than a word remaining.
      *ptr++ = *buf_ptr++;
    } else {
      // Can do a full word at once.
      *((uint32_t*)ptr) = *((uint32_t*)buf_ptr);
      ptr += 4;
      buf_ptr += 4;
    }
  }

  // Transmit response to client.
  unsigned char str[32];
  if (tcpServer_sendStr(debugServer, clientID, (const unsigned char *)("OK, Write, OK, ")) < 0) {
    return 0;
  }
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
int mmio_update(void) {
  /* This backend doesn't to update anything as all calls are blocking */
  return 0;
}

/**
 * Frees all dynamically allocated memory by the interface.
 */
void mmio_free(void) {
  
  // Unmap the file.
  if (mmio_addr != NULL) {
    munmap(mmio_map_addr, mmio_map_length);
  }
  mmio_addr = NULL;
  mmio_length = 0;
  mmio_map_addr = NULL;
  mmio_map_length = 0;
  
  // Close the file.
  if (mmio_fd >= 0) {
    close(mmio_fd);
  }
  mmio_fd = -1;
  
}

int init_mmio_iface(
  const char *file, 
  unsigned long offset, 
  unsigned long length, 
  rvex_iface_t *iface
) {
  
  // Make sure that the offset is word aligned.
  if (offset & 3) {
    printf("mmio: offset must be word aligned\n");
    return -1;
  }
  
  // Get the page size.
  unsigned long page_size = sysconf(_SC_PAGESIZE);
  if (page_size <= 0) {
    printf("mmio: failed to get system page size\n");
    return -1;
  }
  
  // Open the file.
  mmio_fd = open(file, O_RDWR);
  if (mmio_fd < 0) {
    perror("mmio: couldn't open file");
    return -1;
  }
  
  // Figure out what region to map and how.
  unsigned long page_offset = offset % page_size;
  unsigned long page_index = offset / page_size;
  unsigned long page_count = (page_offset + length + page_size-1) / page_size;
  
  // Memory-map the region.
  mmio_map_length = page_index * page_size;
  mmio_map_addr = (unsigned char*)mmap(
    NULL, 
    page_count * page_size,
    PROT_READ | PROT_WRITE,
    MAP_SHARED,
    mmio_fd,
    mmio_map_length
  );
  if (mmio_map_addr == MAP_FAILED) {
    perror("mmio: failed to map memory");
    close(mmio_fd);
    mmio_fd = -1;
    return -1;
  }
  mmio_addr = mmio_map_addr + page_offset;
  mmio_length = length;
  
  printf("Successfully memory-mapped file \"%s\"\n.", file);
  
  *iface = (rvex_iface_t) {
    .read   = mmio_read,
    .write  = mmio_write,
    .update = mmio_update,
    .free   = mmio_free,
  };

  return 0;
}
