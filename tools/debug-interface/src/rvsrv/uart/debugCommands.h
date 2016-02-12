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

#ifndef _DEBUG_COMMANDS_H_
#define _DEBUG_COMMANDS_H_

/**
 * Command codes (with sequence number zero) for all known debug commands
 * supported by the hardware.
 */
#define COMCODE_SET_PAGE         0xA0
#define COMCODE_BULK_WRITE       0xB0
#define COMCODE_BULK_READ        0xC0
#define COMCODE_VOLATILE_PREPARE 0xD0
#define COMCODE_VOLATILE_EXECUTE 0xE0

/**
 * Defines a packet.
 */
typedef struct {
  
  /**
   * Command code and sequence number for the packet.
   */
  unsigned char commandCode;
  
  /**
   * Payload of the packet. Length is specified by len.
   */
  unsigned char data[30];
  
  /**
   * Checksum over the payload and the command byte.
   */
  unsigned char crc;
  
  /**
   * Number of used payload bytes.
   */
  int len;
  
} packet_t;

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
  OT_BARRIER,
  
} operationType_t;

/**
 * Operation callback function type. success is set to 1 when the operation has
 * been executed successfully, or to 0 if a transmission error occured for this
 * operation or an earlier operation. tx and rx are set to point to the
 * transmitted and received packets, if applicable, and finally, data is set to
 * the user data pointer specified when queueing the command.
 */
typedef int (*operationCallbackFn_t)(int success, packet_t *tx, packet_t *rx, void *data);

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
   * The function to call.
   */
  operationCallbackFn_t cb;
  
  /**
   * Data pointer to pass to the function.
   */
  void *cbData;
  
  /**
   * Next operation in the queue.
   */
  struct operation_t_ *next;
  
} operation_t;

/**
 * Updates the debug command system. Returns -1 if an error occured, 0 if the
 * system is idle, or 1 if we want update to be called quickly again to handle
 * potential timeouts.
 */
int debugCommands_update(void);

/**
 * Queues an operation. Returns -1 if an error occurs, or 0 on success.
 */
int debugCommands_queue(const operation_t *op);

/**
 * Frees all dynamically allocated memory by the debugCommands unit.
 */
void debugCommands_free(void);


#endif
