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
#include <unistd.h>

#include "rsp-protocol.h"
#include "rsp-commands.h"
#include "gdb-main.h"

/**
 * Packet receive buffer.
 */
#define RX_BUF_SIZE 16384
static char rxBuf[RX_BUF_SIZE];
static int rxBufLen = 0;

/**
 * Raw transmit buffer.
 */
#define TX_BUF_SIZE 16384
static char txBuf[TX_BUF_SIZE];
static int txBufLen = 0;

/**
 * Packet receiver state.
 */
typedef enum {
  RXS_IDLE,
  RXS_BODY,
  RXS_BODY_ESCAPING,
  RXS_CHECK_1,
  RXS_CHECK_2
} rxState_t;
static rxState_t rxState = RXS_IDLE;
static char rxComputedChecksum = 0;
static char rxReceivedChecksum = 0;

/**
 * Converts a hex character to an integer.
 */
static int hexChar(char c) {
  if ((c >= '0') && (c <= '9')) {
    return c - '0';
  }
  if ((c >= 'a') && (c <= 'f')) {
    return c - 'a' + 10;
  }
  if ((c >= 'A') && (c <= 'F')) {
    return c - 'A' + 10;
  }
  return -1;
}

/**
 * Flushes the transmit buffer.
 */
int rsp_flushTx(void) {
  int remain = txBufLen;
  char *ptr = txBuf;
  
  // Print the outgoing data if debugging is enabled.
  if (gdb_rspDebug && txBufLen) {
    int i;
    printf("rvd -> gdb: ");
    for (i = 0; i < txBufLen; i++) {
      printf("%c", txBuf[i]);
    }
    printf("\n");
  }
  
  while (remain) {
    int count = write(rspConn, ptr, remain);
    if (count < 0) {
      perror("Failed to write to RSP socket");
      return -1;
    } else if (count == 0) {
      fprintf(stderr, "Error: failed to write to RSP socket.\n");
      return -1;
    }
    remain -= count;
    ptr += count;
  }
  txBufLen = 0;
  return 0;
}

/**
 * Pushes a raw character to the transmit buffer.
 */
static int txRaw(char c) {
  if (txBufLen >= TX_BUF_SIZE) {
    if (rsp_flushTx() < 0) {
      return -1;
    }
  }
  txBuf[txBufLen++] = c;
  return 0;
}

/**
 * Escapes and pushes a character to the transmit buffer.
 */
static int tx(char c, char *checksum) {
  if ((c == '#') || (c == '$') || (c == '}')) {
    if (txRaw('}') < 0) {
      return -1;
    }
    c ^= 0x20;
    (*checksum) += '}';
  }
  (*checksum) += c;
  if (txRaw(c) < 0) {
    return -1;
  }
  return 0;
}

/**
 * Processes incoming RSP packets from gdb. Returns 0 on success or
 * -1 on failure; in the latter case an error is printed to stderr.
 */
int rsp_receiveBuf(char *buf, int bufLen) {
  
  // Print the incoming data if debugging is enabled.
  if (gdb_rspDebug) {
    int i;
    printf("rvd <- gdb: ");
    for (i = 0; i < bufLen; i++) {
      printf("%c", buf[i]);
    }
    printf("\n");
  }
  
  // Handle incoming characters.
  while (bufLen--) {
    char c = *buf++;
    
    // Handle packet start character.
    if (c == '$') {
      rxBufLen = 0;
      rxState = RXS_BODY;
      rxComputedChecksum = 0;
      rxReceivedChecksum = 0;
      continue;
    }
    
    // Handle packet start character.
    if ((c == '#') && ((rxState == RXS_BODY) || (rxState == RXS_BODY_ESCAPING))) {
      rxState = RXS_CHECK_1;
      continue;
    }
    
    // Handle escaping.
    if ((c == '}') && ((rxState == RXS_BODY) || (rxState == RXS_BODY_ESCAPING))) {
      rxState = RXS_BODY_ESCAPING;
      continue;
    }
    if (rxState == RXS_BODY_ESCAPING) {
      c ^= 0x20;
      rxState = RXS_BODY;
    }
    
    // Handle packet data.
    if (rxState == RXS_BODY) {
      if (rxBufLen < RX_BUF_SIZE-1) {
        rxBuf[rxBufLen++] = c;
        rxComputedChecksum += c;
      }
      continue;
    }
    
    // Handle first checksum character.
    if (rxState == RXS_CHECK_1) {
      rxReceivedChecksum = hexChar(c) << 4;
      rxState = RXS_CHECK_2;
      continue;
    }
    
    // Handle second checksum character, which marks the end of a packet.
    if (rxState == RXS_CHECK_2) {
      rxReceivedChecksum |= hexChar(c);
      if (rxReceivedChecksum == rxComputedChecksum) {
        if (txRaw('+') < 0) {
          return -1;
        }
        rxBuf[rxBufLen] = 0;
        if (rsp_handlePacket(rxBuf, rxBufLen) < 0) {
          return -1;
        }
      } else {
        if (txRaw('-') < 0) {
          return -1;
        }
      }
      rxState = RXS_IDLE;
      continue;
    }
    
  }
  
  // Flush the transmit buffer.
  if (rsp_flushTx() < 0) {
    return -1;
  }
  
  return 0;
}

/**
 * Sends an RSP packet to gdb, presented as a binary safe buffer. Returns -1 on
 * failure, in which case an error message will be printed.
 */
int rsp_sendPacketBuf(const char *buf, int bufLen) {
  char checksumBuf[3];
  char checksum = 0;
  if (txRaw('$') < 0) {
    return -1;
  }
  while (bufLen--) {
    if (tx(*buf++, &checksum) < 0) {
      return -1;
    }
  }
  if (txRaw('#') < 0) {
    return -1;
  }
  sprintf(checksumBuf, "%02hhx", checksum);
  if (txRaw(checksumBuf[0]) < 0) {
    return -1;
  }
  if (txRaw(checksumBuf[1]) < 0) {
    return -1;
  }
  return 0;
}

/**
 * Sends an RSP packet to gdb, presented as a null terminated string. Returns
 * -1 on failure, in which case an error message will be printed.
 */
int rsp_sendPacketStr(const char *packet) {
  char checksumBuf[3];
  char checksum = 0;
  if (txRaw('$') < 0) {
    return -1;
  }
  while (*packet) {
    if (tx(*packet++, &checksum) < 0) {
      return -1;
    }
  }
  if (txRaw('#') < 0) {
    return -1;
  }
  sprintf(checksumBuf, "%02hhx", checksum);
  if (txRaw(checksumBuf[0]) < 0) {
    return -1;
  }
  if (txRaw(checksumBuf[1]) < 0) {
    return -1;
  }
  return 0;
}

