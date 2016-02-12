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

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <stdint.h>

#include "debugReadWrite.h"
#include "debugCommands.h"
#include "../tcpserv.h"
#include "../main.h"

/**
 * Stores data needed by the callback functions.
 */
typedef struct {
  
  /**
   * TCP client ID which requested the operation.
   */
  int clientID;
  
  /**
   * Hardware address where readBuffer starts.
   */
  uint32_t address;
  
  /**
   * Read buffer pointer. Also used to store whether this was a read or write;
   * this is always null for writes.
   */
  unsigned char *buffer;
  
  /**
   * Number of bytes read or written. For reads, this is also the allocation
   * size for buffer.
   */
  int bufSize;
  
  /**
   * Whether the last volatile bus operation performed returned a bus fault.
   */
  int lastFault;
  
  /**
   * The fault code for the last volatile bus operation performed if lastFault
   * is set.
   */
  uint32_t lastFaultCode;
  
} callbackData_t;

/**
 * Writes data to the read buffer in cbData, starting at the offset determined
 * by the supplied address and the start address in cbData, making sure that
 * no out-of-range accesses are made. The address is suppied as a pointer to a
 * buffer containing the address in big-endian format, as it is sent to the
 * hardware.
 */
static void writeToReadBuffer(callbackData_t *cbData, unsigned char *addressBuf, unsigned char *data, int count) {
  uint32_t address;
  int offset, i;
  
  // Determine the address.
  address = addressBuf[0];
  address <<= 8;
  address |= addressBuf[1];
  address <<= 8;
  address |= addressBuf[2];
  address <<= 8;
  address |= addressBuf[3];
  
  // Determine the start offset within the read buffer.
  offset = address - cbData->address;
  
  for (i = 0; i < count; i++) {
    if ((offset >= 0) && (offset < cbData->bufSize)) {
      cbData->buffer[offset] = data[i];
    }
    offset++;
  }
}

/**
 * Stores the result from a bulk read command in the read buffer.
 */
static int onBulkRead(int success, packet_t *tx, packet_t *rx, void *data) {
  callbackData_t *cbData = (callbackData_t*)data;
  if (!cbData) {
    printf("onBulkRead() was called without parameter data, this should never happen...\n");
    return -1;
  }
  if (!(cbData->buffer)) {
    printf("onBulkRead() was called without data buffer, this should never happen...\n");
    return -1;
  }
  
  // If this is just reporting a failure, don't do anything.
  if (!success) {
    return 0;
  }
  
  // Something is wrong if we don't have access to the transmitted or received
  // packets.
  if (!tx || !rx) {
    printf("onBulkRead() was called without pointers to packets, this should never happen...\n");
    return -1;
  }
  
  // Write the received data to the read buffer.
  writeToReadBuffer(cbData, tx->data, rx->data, rx->len);
  
  return 0;
}

/**
 * Stores the result from a volatile bus access in the read buffer and fault
 * storage.
 */
static int onVolatileComplete(int success, packet_t *tx, packet_t *rx, void *data) {
  callbackData_t *cbData = (callbackData_t*)data;
  if (!cbData) {
    printf("onVolatileComplete() was called without parameter data, this should never happen...\n");
    return -1;
  }
  
  // If this is just reporting a failure, don't do anything.
  if (!success) {
    return 0;
  }
  
  // Something is wrong if we don't have access to the transmitted or received
  // packets.
  if (!tx || !rx) {
    printf("onVolatileComplete() was called without pointers to packets, this should never happen...\n");
    return -1;
  }
  
  // Write the received data to the read buffer if this was a read.
  if (cbData->buffer) {
    writeToReadBuffer(cbData, tx->data, rx->data, rx->len);
  }
  
  // Store fault codes.
  cbData->lastFault = rx->data[4] & 0x01;
  if (cbData->lastFault) {
    cbData->lastFaultCode = rx->data[0];
    cbData->lastFaultCode <<= 8;
    cbData->lastFaultCode |= rx->data[1];
    cbData->lastFaultCode <<= 8;
    cbData->lastFaultCode |= rx->data[2];
    cbData->lastFaultCode <<= 8;
    cbData->lastFaultCode |= rx->data[3];
  }
  
  return 0;
}

/**
 * Formats and returns the operation result to the TCP client.
 */
static int onReadWriteComplete(int success, packet_t *tx, packet_t *rx, void *data) {
  unsigned char str[32];
  int i;
  callbackData_t *cbData = (callbackData_t*)data;
  if (!cbData) {
    printf("onReadWriteComplete() was called without parameter data, this should never happen...\n");
    return -1;
  }
  
  // Return a communication error if success is 0.
  if (!success) {
    if (tcpServer_sendStr(debugServer, cbData->clientID, (const unsigned char *)(cbData->buffer ? "Error, Read, CommunicationError;\n" : "Error, Write, CommunicationError;\n")) < 0) {
      if (cbData->buffer) free(cbData->buffer);
      free(cbData);
      return 0;
    }
    if (cbData->buffer) free(cbData->buffer);
    free(cbData);
    return 0;
  }
  
  // Write the result tokens which are always present.
  if (tcpServer_sendStr(debugServer, cbData->clientID, (const unsigned char *)(cbData->buffer ? "OK, Read, " : "OK, Write, ")) < 0) {
    if (cbData->buffer) free(cbData->buffer);
    free(cbData);
    return 0;
  }
  if (tcpServer_sendStr(debugServer, cbData->clientID, (const unsigned char *)(cbData->lastFault ? "Fault, " : "OK, ")) < 0) {
    if (cbData->buffer) free(cbData->buffer);
    free(cbData);
    return 0;
  }
  sprintf((char *)str, "%08X, %d", cbData->address, cbData->bufSize);
  if (tcpServer_sendStr(debugServer, cbData->clientID, str) < 0) {
    if (cbData->buffer) free(cbData->buffer);
    free(cbData);
    return 0;
  }
  
  // Write the result-specific tokens.
  if (cbData->lastFault) {
    
    // Write fault code.
    sprintf((char *)str, ", %08X;\n", cbData->lastFaultCode);
    if (tcpServer_sendStr(debugServer, cbData->clientID, str) < 0) {
      if (cbData->buffer) free(cbData->buffer);
      free(cbData);
      return 0;
    }
    
  } else if (cbData->buffer) {
    
    // Dump the data buffer.
    if (tcpServer_sendStr(debugServer, cbData->clientID, (const unsigned char *)", ") < 0) {
      free(cbData->buffer);
      free(cbData);
      return 0;
    }
    for (i = 0; i < cbData->bufSize; i++) {
      sprintf((char *)str, "%02hhX", cbData->buffer[i]);
      if (tcpServer_sendStr(debugServer, cbData->clientID, str) < 0) {
        free(cbData->buffer);
        free(cbData);
        return 0;
      }
    }
    if (tcpServer_sendStr(debugServer, cbData->clientID, (const unsigned char *)";\n") < 0) {
      free(cbData->buffer);
      free(cbData);
      return 0;
    }
    
  } else {
    
    // No special token for writes.
    if (tcpServer_sendStr(debugServer, cbData->clientID, (const unsigned char *)";\n") < 0) {
      free(cbData);
      return 0;
    }
    
  }
  
  if (cbData->buffer) free(cbData->buffer);
  free(cbData);
  return 0;
}

/**
 * Queues the operations needed to perform a volatile bus command.
 */
static int queueVolatile(uint32_t address, uint32_t writeData, int flags, callbackData_t *cbData) {
  operation_t op;
  op.cbData = (void*)cbData;
  
  // We should wait with issuing the prepare command before all other bus
  // operations have completed.
  op.t = OT_BARRIER;
  op.cb = 0;
  if (debugCommands_queue(&op) < 0) {
    return -1;
  }
  
  // Send the prepare command.
  op.t = OT_COMMAND;
  op.p.commandCode = COMCODE_VOLATILE_PREPARE;
  op.p.data[0] = (address   >> 24) & 0xFF;
  op.p.data[1] = (address   >> 16) & 0xFF;
  op.p.data[2] = (address   >>  8) & 0xFF;
  op.p.data[3] = (address   >>  0) & 0xFC;
  op.p.data[4] = (writeData >> 24) & 0xFF;
  op.p.data[5] = (writeData >> 16) & 0xFF;
  op.p.data[6] = (writeData >>  8) & 0xFF;
  op.p.data[7] = (writeData >>  0) & 0xFF;
  op.p.data[8] = flags;
  op.p.len = 9;
  op.cb = 0;
  if (debugCommands_queue(&op) < 0) {
    return -1;
  }
      
  // We need to ensure that the command has been prepared by the hardware
  // before sending the command to execute it.
  op.t = OT_BARRIER;
  op.cb = 0;
  if (debugCommands_queue(&op) < 0) {
    return -1;
  }
  
  // Send the execute command.
  op.t = OT_COMMAND;
  op.p.commandCode = COMCODE_VOLATILE_EXECUTE;
  op.p.len = 0;
  op.cb = &onVolatileComplete;
  if (debugCommands_queue(&op) < 0) {
    return -1;
  }
  
  // We need to make sure that the command has been executed before giving any
  // commands which might override the prepared command.
  op.t = OT_BARRIER;
  op.cb = 0;
  if (debugCommands_queue(&op) < 0) {
    return -1;
  }
  
  return 0;
}


/**
 * Try reading over the UART interface.
 *
 * At most 4096 bytes may be read at once. The reply sent will be one of:
 * 
 *   OK, Read, OK, < 8 hex chars: address>, < 1-.. decimal chars: count>, < 2*count hex chars: data>;
 *   OK, Read, Fault, < 8 hex chars: address>, < 1-.. decimal chars: count>, < 8 hex chars: fault ID>;
 *   Error, CommunicationError
 * 
 * Bus faults are only checked for the last bus operation; if there are any bus
 * errors prior, these bus operations silently fail in hardware.
 */
int handleRead(uint32_t address, uint32_t buf_size, int clientID) {
  callbackData_t *cbData;
  operation_t op;

  // Allocate memory for the callback data structure.
  cbData = (callbackData_t*)malloc(sizeof(*cbData));
  if (!cbData) {
    perror("handleRead: Failed to allocate memory to service debug read command");
    return -1;
  }
  cbData->clientID = clientID;
  cbData->address = address;
  cbData->bufSize = buf_size;
  cbData->buffer = malloc(buf_size);
  cbData->lastFault = 0;
  cbData->lastFaultCode = 0;

  if (!cbData->buffer) {
    perror("handleRead: Failed to allocate memory to service debug read command");
    free(cbData);
    return -1;
  }
  
  // All operations which will use callback data, will use the same callback
  // data. So we just set the pointer here once.
  op.cbData = (void*)cbData;
  
  // Queue the necessary debug operations for handling this command.
  uint32_t curAddress = cbData->address;
  int remain = cbData->bufSize;
  unsigned char *bufPtr = cbData->buffer;
    
  // Handle reads
  while (remain) {

    if (!(curAddress & 0x3) && (remain >= 8)) {
      // The remain >= 8 condition is used to ensure that the last word is
      // accessed using a volatile bus write, so the fault signal is always
      // somewhat valid.

      int numWords;

      // We can do a bulk read.

      // Determine how many words we can write.
      if (remain > 32) {
        numWords = 7;
      } else {
        numWords = (remain - 4) / 4;
      }

      // Make sure we don't cross a 4kb boundary mid write (auto-increment
      // does not support this).
      if ((curAddress + numWords*4) > ((curAddress & 0xFFFFF000) + 0x00001000)) {
        numWords = (((curAddress & 0xFFFFF000) + 0x00001000) - curAddress) / 4;
      }

      // Queue the bulk read command.
      op.t = OT_COMMAND;
      op.p.commandCode = COMCODE_BULK_READ;
      op.p.data[0] = (curAddress >> 24) & 0xFF;
      op.p.data[1] = (curAddress >> 16) & 0xFF;
      op.p.data[2] = (curAddress >>  8) & 0xFF;
      op.p.data[3] = (curAddress >>  0) & 0xFF;
      op.p.data[4] = (curAddress + (numWords*4)) & 0xFF;
      op.p.len = 5;
      op.cb = &onBulkRead;
      if (debugCommands_queue(&op) < 0) {
        return -1;
      }

      // Update counters and pointers.
      curAddress += numWords*4;
      remain -= numWords*4;
      bufPtr += numWords*4;

    } else {

      int numUsedBytes;
      uint32_t alignedAddress;

      // We need to do a volatile word read.

      // Align the address to a word address.
      alignedAddress = curAddress & 0xFFFFFFFC;

      // Queue the volatile bus operation.
      if (queueVolatile(alignedAddress, 0, 0, op.cbData) < 0) {
        return -1;
      }

      // Determine how many bytes we're actually going to use from the read
      // word.
      numUsedBytes = 4;
      numUsedBytes -= (uint32_t)(curAddress - alignedAddress);
      if (remain < numUsedBytes) {
        numUsedBytes = remain;
      }

      // Update counters and pointers.
      curAddress += numUsedBytes;
      remain -= numUsedBytes;
      bufPtr += numUsedBytes;

    }

  }
  
  // Insert a barrier with a callback to detect when we're done.
  op.t = OT_BARRIER;
  op.cb = onReadWriteComplete;
  if (debugCommands_queue(&op) < 0) {
    return -1;
  }
  
  // Queued successfully.
  return 0;
}

/**
 * Try writing over the UART interface.
 *
 * At most 4096 bytes may be written at once. The reply sent will be one of:
 * 
 *   OK, Write, OK, < 8 hex chars: address>, < 1-.. decimal chars: count>;
 *   OK, Write, Fault, < 8 hex chars: address>, < 1-.. decimal chars: count>, < 8 hex chars: fault ID>;
 *   Error, CommunicationError
 * 
 * Bus faults are only checked for the last bus operation; if there are any bus
 * errors prior, these bus operations silently fail in hardware.
 */
int handleWrite(uint32_t address, unsigned char *buffer, uint32_t buf_size,
    int clientID) {
  callbackData_t *cbData;
  operation_t op;

  // Allocate memory for the callback data structure.
  cbData = (callbackData_t*)malloc(sizeof(*cbData));
  if (!cbData) {
    perror("handleRead: Failed to allocate memory to service debug read command");
    return -1;
  }
  cbData->clientID = clientID;
  cbData->address = address;
  cbData->bufSize = buf_size;
  cbData->buffer = 0;
  cbData->lastFault = 0;
  cbData->lastFaultCode = 0;
  
  // All operations which will use callback data, will use the same callback
  // data. So we just set the pointer here once.
  op.cbData = (void*)cbData;
  
  // Queue the necessary debug operations for handling this command.
  uint32_t curAddress = cbData->address;
  int remain = cbData->bufSize;
  unsigned char *bufPtr = buffer;
  int curPage = -1;

  // Handle writes
  while (remain) {

    if (!((curAddress & 0xFFF) % 28) && (remain >= 8)) {
      // The remain >= 8 condition is used to ensure that the last word is
      // accessed using a volatile bus write, so the fault signal is always
      // somewhat valid.

      int numWords;
      int page;

      // We can do a bulk write.

      // Determine how many words we can write.
      if (remain > 32) {
        numWords = 7;
      } else {
        numWords = (remain - 4) / 4;
      }

      // Make sure we don't cross a 4kb boundary mid write (auto-increment
      // does not support this).
      if ((curAddress + numWords*4) > ((curAddress & 0xFFFFF000) + 0x00001000)) {
        numWords = (((curAddress & 0xFFFFF000) + 0x00001000) - curAddress) / 4;
      }

      // Determine the page which this would belong to.
      page = curAddress >> 12;

      // Switch page if needed.
      if (page != curPage) {

        // We don't want to change the page while any previous writes may not
        // have been completed, so we need a barrier.
        op.t = OT_BARRIER;
        op.cb = 0;
        if (debugCommands_queue(&op) < 0) {
          return -1;
        }

        // Insert the set page command.
        op.t = OT_COMMAND;
        op.p.commandCode = COMCODE_SET_PAGE;
        op.p.data[0] = (curAddress >> 24) & 0xFF;
        op.p.data[1] = (curAddress >> 16) & 0xFF;
        op.p.data[2] = (curAddress >>  8) & 0xF0;
        op.p.len = 3;
        if (debugCommands_queue(&op) < 0) {
          return -1;
        }

        // We don't want to change write until we're sure that the page
        // command has been executed, so we need another barrier.
        op.t = OT_BARRIER;
        if (debugCommands_queue(&op) < 0) {
          return -1;
        }

        // Update the current page.
        curPage = page;

      }

      // Queue the bulk write command.
      op.t = OT_COMMAND;
      op.p.commandCode = COMCODE_BULK_WRITE;
      op.p.data[0] = (curAddress & 0xFFF) / 28;
      memcpy(&(op.p.data[1]), bufPtr, numWords*4);
      op.p.len = numWords*4+1;
      printf("Write to address %x, len %d\n", curAddress, op.p.len);
      if (debugCommands_queue(&op) < 0) {
        return -1;
      }

      // Update counters and pointers.
      curAddress += numWords*4;
      remain -= numWords*4;
      bufPtr += numWords*4;

    } else if (!(curAddress & 0x3) && (remain >= 4)) {

      uint32_t writeData;

      // We can do a volatile word write.
      writeData = *(bufPtr+0);
      writeData <<= 8;
      writeData |= *(bufPtr+1);
      writeData <<= 8;
      writeData |= *(bufPtr+2);
      writeData <<= 8;
      writeData |= *(bufPtr+3);
      printf("Write to address %x, len %d\n", curAddress, 4);
      if (queueVolatile(curAddress & 0xFFFFFFFC, writeData, 0xF8, op.cbData) < 0) {
        return -1;
      }

      // Update counters and pointers.
      curAddress += 4;
      remain -= 4;
      bufPtr += 4;

    } else if (!(curAddress & 0x1) && (remain >= 2)) {

      uint32_t writeData;

      // We can do a volatile halfword write.
      writeData = *(bufPtr+0);
      writeData <<= 8;
      writeData |= *(bufPtr+1);
      writeData <<= 8;
      writeData |= *(bufPtr+0);
      writeData <<= 8;
      writeData |= *(bufPtr+1);
      printf("Write to address %x, len %d\n", curAddress, 2);
      if (queueVolatile(curAddress & 0xFFFFFFFC, writeData, (curAddress & 0x2) ? 0x38 : 0xC8, op.cbData) < 0) {
        return -1;
      }

      // Update counters and pointers.
      curAddress += 2;
      remain -= 2;
      bufPtr += 2;

    } else {

      uint32_t writeData;
      int mask;

      // We need to do a volatile byte write.
      switch (curAddress & 0x3) {
        case 0: mask = 0x8; break;
        case 1: mask = 0x4; break;
        case 2: mask = 0x2; break;
        case 3: mask = 0x1; break;
      }
      writeData = *bufPtr;
      writeData <<= 8;
      writeData |= *bufPtr;
      writeData <<= 8;
      writeData |= *bufPtr;
      writeData <<= 8;
      writeData |= *bufPtr;
      printf("Write to address %x, len %d\n", curAddress, 1);
      if (queueVolatile(curAddress & 0xFFFFFFFC, writeData, (mask << 4) | 0x08, op.cbData) < 0) {
        return -1;
      }

      // Update counters and pointers.
      curAddress += 1;
      remain -= 1;
      bufPtr += 1;

    }

  }

  // Insert a barrier with a callback to detect when we're done.
  op.t = OT_BARRIER;
  op.cb = onReadWriteComplete;
  if (debugCommands_queue(&op) < 0) {
    return -1;
  }
  
  // Queued successfully.
  return 0;
}


