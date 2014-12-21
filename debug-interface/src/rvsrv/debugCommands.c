/* Debug interface for standalone r-VEX processor
 * 
 * Copyright (C) 2008-2014 by TU Delft.
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
 * Copyright (C) 2008-2014 by TU Delft.
 */

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>

#include "debugCommands.h"
#include "serial.h"
#include "main.h"


//-----------------------------------------------------------------------------
// Lowlevel packet handling
//-----------------------------------------------------------------------------

/**
 * Defines a packet.
 */
typedef struct {
  
  /**
   * Command code and sequence number for the packet.
   */
  char commandCode;
  
  /**
   * Payload of the packet. Length is specified by len.
   */
  char data[30];
  
  /**
   * Checksum over the payload and the command byte.
   */
  char crc;
  
  /**
   * Number of used payload bytes.
   */
  int len;
  
} packet_t;

/**
 * CRC polynomial used for the debug packets.
 */
#define CRC_POLYNOMIAL 0x07

/**
 * Updates an 8 bit CRC.  Code is based on one of the CRC methods from
 * http://www.zorc.breitbandkatze.de/crc.html.
 */
static void updateCrc(unsigned char *crc, const unsigned char data) {
  unsigned char bit;
  int i;
  
  for (i = 0x80; i; i >>= 1) {
    bit = *crc & 0x80;
    *crc <<= 1;
    if (data & i) bit ^= 0x80;
    if (bit) *crc ^= CRC_POLYNOMIAL;
  }
  
}

/**
 * Computes the CRC over a packet and returns it.
 */
static char crcPacket(const packet_t *packet) {
  unsigned char crc = 0;
  int i;
  
  // CRC the command code.
  updateCrc(&crc, (unsigned char)packet->commandCode);
  
  // CRC the rest of the packet.
  for (i = 0; i < packet->len; i++) {
    updateCrc(&crc, (unsigned char)packet->data[i]);
  }
  
  return (char)crc;
  
}

/**
 * Returns the sequence number of the given packet.
 */
static int getPacketSequence(const packet_t *packet) {
  return ((int)packet->commandCode) & 0x0F;
}

/**
 * Sets the sequence number for the given packet.
 */
static void setPacketSequence(packet_t *packet, int sequence) {
  packet->commandCode &= 0xF0;
  packet->commandCode |= sequence & 0x0F;
}

/**
 * Tries to pull a packet from the serial buffer. Packets with incorrect
 * checksum are ignored. Return value is 1 if a packet was received and was
 * placed in packet, 0 if no packet is available, or -1 if an error occured.
 */
static int receivePacket(packet_t *packet) {
  int d, i;
  
  // Receive buffer.
  static char buffer[32];
  
  // Number of characters received already.
  static int bufPtr = 0;
  
  // Pull data from the receive buffer until it's empty (we'll break if we
  // find a valid packet).
  while ((d = serial_debugReceive(tty)) >= 0) {
    
    if (d > 255) {
      
      // End of packet marker. Make sure the packet is at least two bytes long
      // and shorter than the size of the receive buffer.
      if ((bufPtr < 2) || (bufPtr > 32)) {
        bufPtr = 0;
        continue;
      }
      
      // Assemble the packet.
      packet->commandCode = buffer[0];
      packet->crc = buffer[bufPtr - 1];
      packet->len = bufPtr - 2;
      for (i = 0; i < packet->len; i++) {
        packet->data[i] = buffer[i + 1];
      }
      
      // Reset the receive buffer.
      bufPtr = 0;
      
      // Return the packet if the CRC is correct.
      if (crcPacket(packet) == packet->crc) {
        return 1;
      }
      
    } else {
      
      // Append the byte to the buffer.
      if (bufPtr < 32) {
        buffer[bufPtr] = d;
      }
      bufPtr++;
      
    }
    
  }
  
  // No packet ready yet.
  return 0;
  
}

/**
 * Transmits a packet. Returns -1 if transmitting failed, or 0 if the transmit
 * was successful.
 */
static int transmitPacket(packet_t *packet) {
  int i;
  
  // Compute the CRC of the packet.
  packet->crc = crcPacket(packet);
  
  // Transmit the packet.
  if (serial_debugSend(tty, (int)(packet->commandCode) & 0xFF) < 0) {
    return -1;
  }
  for (i = 0; i < packet->len; i++) {
    if (serial_debugSend(tty, (int)(packet->data[i]) & 0xFF) < 0) {
      return -1;
    }
  }
  if (serial_debugSend(tty, (int)(packet->crc) & 0xFF) < 0) {
    return -1;
  }
  
  // Send the end-of-packet marker.
  if (serial_debugSend(tty, 256) < 0) {
    return -1;
  }
  
  // Sending was successful.
  return 0;
  
}


//-----------------------------------------------------------------------------
// Operation queue
//-----------------------------------------------------------------------------

/**
 * Operation type enumeration.
 */
typedef enum {
  
  /**
   * Defines a normal debug command, which is sent to the rvex as is.
   */
  OT_COMMAND,
  
  /**
   * Defines a barrier. This operation does not do anything except wait until
   * all previous commands have been executed.
   */
  OT_BARRIER
  
} operationType_t;

/**
 * Defines an item in an operation queue.
 */
typedef struct operation_t_ {
  
  /**
   * Operation type.
   */
  operationType_t t;
  
  /**
   * Packet to be sent for command operations.
   */
  packet_t p;
  
  /**
   * Next operation in the queue.
   */
  struct operation_t_ *next;
  
} operation_t;

/**
 * Defines an operation queue.
 */
typedef struct {
  
  /**
  * Head (next operation to be executed) and tail of the operation queue.
  */
  operation_t *head;
  operation_t *tail;
  
} operationQueue_t;

/**
 * Pushes the given operation into the queue. Returns -1 if something goes
 * wrong.
 */
static int opQueuePush(operationQueue_t *queue, const operation_t *op) {
  operation_t *ptr;
  
  // Make a copy of the given operation.
  ptr = (operation_t*)malloc(sizeof(operation_t));
  if (!ptr) {
    perror("Failed to push operation into queue");
    return -1;
  }
  memcpy(ptr, op, sizeof(operation_t));
  
  // Make sure the next pointer is set to null to mark the end of the queue.
  ptr->next = 0;
  
  // Insert the operation into the queue.
  if (!queue->tail) {
    
    // The queue was empty.
    queue->head = ptr;
    queue->tail = ptr;
    
  } else {
    
    // There was already stuff in the queue.
    queue->tail->next = ptr;
    queue->tail = ptr;
    
  }
  
}

/**
 * Returns the next operation which should be performed, or null if there is
 * none.
 */
static operation_t *opQueuePeek(operationQueue_t *queue) {
  return queue->head;
}

/**
 * Pops and frees the current operation from the queue, without returning it.
 */
static void opQueuePop(operationQueue_t *queue) {
  operation_t *ptr;
  
  // If there is nothing to pop, return.
  if (!queue->head) {
    queue->tail = 0;
    return;
  }
    
  // Remember the pointer to the operation which we're popping.
  ptr = queue->head;
  
  // Update the pointers in the linked list.
  if (queue->head == queue->tail) {
    queue->tail = 0;
    queue->head = 0;
  } else {
    queue->head = ptr->next;
    if (!queue->head) {
      queue->tail = 0;
    }
  }
  
  // Free the popped operation.
  free(ptr);
  
}

/**
 * Frees everything in the operation queue (but not the queue structure
 * itself).
 */
static void opQueueFree(operationQueue_t *queue) {
  
  // Just pop until the queue is empty, there is no algorithmically faster way.
  while (queue->head) {
    opQueuePop(queue);
  }
  
}


//-----------------------------------------------------------------------------
// Command sequencing
//-----------------------------------------------------------------------------

/**
 * Incoming operations which need to be schedueled.
 */
static operationQueue_t opQueue = {0, 0};

/**
 * Operations for which we did not receive a reply which need to be issued
 * again.
 */
static operationQueue_t reissueQueue = {0, 0};

/**
 * Contains the packet which was scheduled using the indexed sequence number.
 * Valid only when slotsValid is set.
 */
static packet_t slots[16];

/**
 * Set to 1 when a slot is valid (has been sent, but with no reply yet) or
 * 0 otherwise.
 */
static char slotsValid[16] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

/**
 * Transmit sequence counter. This is set to the next sequence number which
 * should be used to send a command.
 */
static int txSeqCounter = 0;

/**
 * Receive sequence counter. This is set to the sequence number which we're
 * expecting to receive next, or 1 + the sequence number of the packet which
 * we last received.
 */
static int rxSeqCounter = 0;

/**
 * Number of times where we had a timeout occur without receiving *anything*
 * from the hardware.
 */
static int timeoutCount = 0;

/**
 * Receives and handles all packets available on the input stream. Returns -1
 * on failure, 0 if no packets were available, or 1 if at least one packet
 * has been handled.
 */
static int receivePackets(void) {
  int retval;
  packet_t receivedPacket;
  operation_t operation;
  int sequence;
  int handledAnything = 0;
  
  // Handle received packets.
  while (retval = receivePacket(&receivedPacket)) {
    if (retval < 0) {
      return -1;
    }
    
    // Update sequencing.
    sequence = getPacketSequence(&receivedPacket);
    
    // If this is not the packet we were expecting, put all the packets which
    // were skipped in the re-issue queue.
    while (rxSeqCounter != sequence) {
      if (slotsValid[rxSeqCounter]) {
        slotsValid[rxSeqCounter] = 0;
        operation.p = slots[rxSeqCounter];
        opQueuePush(&reissueQueue, &operation);
      }
      rxSeqCounter++;
      rxSeqCounter &= 0xF;
    }
    
    // Mark the packet which was sent with the same sequence number as valid.
    slotsValid[rxSeqCounter] = 0;
    rxSeqCounter++;
    rxSeqCounter &= 0xF;
    
    // Remember that we've handled a packet.
    handledAnything = 1;
    
    // Figure out if we actually need to do something with the packet or if it
    // was just an ack.
    // TODO
    
  }
  
  // Return whether we've handled any packets.
  return handledAnything;
}

/**
 * Returns nonzero if the re-issue queue is empty and we're not waiting for any
 * ack packets.
 */
static int isIdle(void) {
  return (txSeqCounter == rxSeqCounter) && (!opQueuePeek(&reissueQueue));
}

/**
 * Tries to send a packet using the next available sequence number. Returns 1
 * if the packet was issued, 0 if not, or -1 if an error occured.
 */
static int issuePacket(packet_t *packet) {
  
  // Make sure the slot is clear.
  if (slotsValid[txSeqCounter]) {
    return 0;
  }
  
  // Set the sequence number.
  setPacketSequence(packet, txSeqCounter);
  
  // Transmit the packet.
  if (transmitPacket(packet) < -1) {
    return -1;
  }
  
  // Update sequencing logic.
  slots[txSeqCounter] = *packet;
  slotsValid[txSeqCounter] = 1;
  txSeqCounter++;
  txSeqCounter &= 0xF;
  
  // Packet has been issued.
  return 1;
}

/**
 * Tries to (re)issue as much commands as possible.
 */
static int transmitPackets(void) {
  operation_t *op;
  int retval;
  
  // Try to re-issue commands which failed before.
  while (op = opQueuePeek(&reissueQueue)) {
    
    // Try to issue the packet.
    retval = issuePacket(&(op->p));
    if (retval < 0) {
      return -1;
    } else if (retval == 0) {
      return 0;
    }
    
    // Packet issued, pop it from the queue.
    opQueuePop(&reissueQueue);
    
  }
  
  // Try to issue new commands.
  while (op = opQueuePeek(&opQueue)) {
    
    switch (op->t) {
      
      case OT_COMMAND:
        
        // Try to issue the packet.
        retval = issuePacket(&(op->p));
        if (retval < 0) {
          return -1;
        } else if (retval == 0) {
          return 0;
        }
        
        // Packet issued, pop it from the queue.
        opQueuePop(&opQueue);
        break;
      
      case OT_BARRIER:
        
        // Pop the barrier command only when we're idle.
        if (!isIdle()) {
          return 0;
        }
        opQueuePop(&opQueue);
        break;
        
    }
    
  }
  
  return 0;
}

/**
 * Returns nonzero if all pending commands have been issued.
 */
static int isDone(void) {
  return (!opQueuePeek(&opQueue) && isIdle());
}


//-----------------------------------------------------------------------------
// API for the next abstraction layer
//-----------------------------------------------------------------------------

/**
 * Updates the debug command system. Returns -1 if an error occured, 0 if the
 * system is idle, or 1 if we want update to be called quickly again to handle
 * potential timeouts.
 */
int debugCommands_update(void) {
  
  
  
  // Return 1 if we're not done yet, so update will be called again soon
  // whether new data is available or not.
  return !isDone();
}



