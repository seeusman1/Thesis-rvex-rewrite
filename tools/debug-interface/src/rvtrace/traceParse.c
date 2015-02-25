/* Debug interface for standalone r-VEX processor
 * 
 * Copyright (C) 2008-2015 by TU Delft.
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
 * Copyright (C) 2008-2015 by TU Delft.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "traceParse.h"

/**
 * Scans count characters.
 */
#define SCAN(count) \
  if (*rawDataRemain < count) return 0; \
  d = *rawDataPtr; \
  *rawDataPtr += count; \
  *rawDataRemain -= count \

/**
 * Decodes the next trace packet. Returns 1 if a normal packet was encountered,
 * 2 if a normal packet implying a cycle end was encountered, 0 if no more
 * packets are available or -1 if an error occured, in which case an error will
 * be printed to stderr.
 */
int getTracePacket(
  uint8_t **rawDataPtr,
  int *rawDataRemain,
  trace_packet_t *packet,
  int numLanes
) {
  
  int endOfCycle = 0;
  uint8_t *d;
  int hasExFlags;
  int hasRegs;
  
  // Scan beyond zero padding.
  while ((*rawDataRemain) && !(**rawDataPtr)) {
    (*rawDataRemain)--;
    (*rawDataPtr)++;
  }
  
  // If we're out of data, return 0.
  if (!(*rawDataRemain)) {
    return 0;
  }
  
  // Reset validity flags.
  packet->hasPC               = 0;
  packet->hasMem              = 0;
  packet->hasWrittenGP        = 0;
  packet->hasWrittenLink      = 0;
  packet->hasWrittenBranch    = 0;
  packet->hasTrapped          = 0;
  packet->hasNewConfiguration = 0;
  
  // Scan FLAGS.
  SCAN(1);
  packet->hasPC  = (d[0] & (1 << 7)) != 0;
  packet->hasMem = (d[0] & (1 << 6)) != 0;
  hasRegs        = (d[0] & (1 << 5)) != 0;
  hasExFlags     = (d[0] & (1 << 0)) != 0;
  packet->lane   = (d[0] >> 1) & 15;
  if (packet->lane >= numLanes) {
    fprintf(stderr, "Error: trace packet encountered for lane %d, while only %d lanes are available.\n", packet->lane, numLanes);
    return -1;
  }
  if (packet->lane == numLanes - 1) {
    endOfCycle = 1;
  }
  
  // Scan PC information.
  if (packet->hasPC) {
    SCAN(1);
    packet->hasBranched = 0;
    packet->pc = d[0] & 0xFC;
    switch (d[0] & 0x03) {
      case 3:
        packet->hasBranched = 1;
        // continue
      case 2:
        SCAN(3);
        packet->hasPC = 0xFFFFFFFF;
        packet->pc |= ((uint32_t)d[0]) << 8;
        packet->pc |= ((uint32_t)d[1]) << 16;
        packet->pc |= ((uint32_t)d[2]) << 24;
        break;
      case 1:
        SCAN(1);
        packet->hasPC = 0x0000FFFF;
        packet->pc |= ((uint32_t)d[0]) << 8;
        break;
      case 0:
        packet->hasPC = 0x000000FF;
        break;
    }
  }
  
  // Scan memory information.
  if (packet->hasMem) {
    SCAN(1);
    switch (d[0]) {
      case 0x0: // Read word.
        packet->memAddr = 0;
        packet->hasMem = -1;
        break;
      case 0x8: // Write byte, index 0.
        packet->memAddr = 0;
        packet->hasMem = 1;
        break;
      case 0x4: // Write byte, index 1.
        packet->memAddr = 1;
        packet->hasMem = 1;
        break;
      case 0x2: // Write byte, index 2.
        packet->memAddr = 2;
        packet->hasMem = 1;
        break;
      case 0x1: // Write byte, index 3.
        packet->memAddr = 3;
        packet->hasMem = 1;
        break;
      case 0xC: // Write half, index 0.
        packet->memAddr = 0;
        packet->hasMem = 2;
        break;
      case 0x3: // Write half, index 1.
        packet->memAddr = 2;
        packet->hasMem = 2;
        break;
      case 0xF: // Write word.
        packet->memAddr = 0;
        packet->hasMem = 4;
        break;
      default:
        fprintf(stderr, "Error: encountered trace packet with invalid MEMFLAGS field.\n");
        return -1;
    }
    
    SCAN(4);
    packet->memAddr += d[0];
    packet->memAddr |= ((uint32_t)d[1]) << 8;
    packet->memAddr |= ((uint32_t)d[2]) << 16;
    packet->memAddr |= ((uint32_t)d[3]) << 24;
    
    if (packet->hasMem >= 1) {
      SCAN(1);
      packet->memWriteData = d[0];
    }
    if (packet->hasMem >= 2) {
      SCAN(1);
      packet->memWriteData |= ((uint32_t)d[0]) << 8;
    }
    if (packet->hasMem >= 4) {
      SCAN(2);
      packet->memWriteData |= ((uint32_t)d[0]) << 16;
      packet->memWriteData |= ((uint32_t)d[1]) << 14;
    }
  }
  
  // Scan register information.
  if (hasRegs) {
    SCAN(1);
    packet->hasWrittenBranch = (d[0] & (1 << 7)) != 0;
    packet->hasWrittenLink   = (d[0] & (1 << 6)) != 0;
    packet->hasWrittenGP     = d[0] & 0x3F;
    
    if (packet->hasWrittenLink || packet->hasWrittenGP) {
      SCAN(4);
      packet->gpWriteData  = d[0];
      packet->gpWriteData |= ((uint32_t)d[1]) << 8;
      packet->gpWriteData |= ((uint32_t)d[2]) << 16;
      packet->gpWriteData |= ((uint32_t)d[3]) << 24;
      packet->linkWriteData = packet->gpWriteData;
    }
    
    if (packet->hasWrittenBranch) {
      SCAN(2);
      packet->hasWrittenBranch = d[0];
      packet->branchWriteData = d[1];
    }
  }
  
  // Scan EXFLAGS.
  if (hasExFlags) {
    SCAN(1);
    packet->hasTrapped          = (d[0] & (1 << 7)) != 0;
    packet->hasNewConfiguration = (d[0] & (1 << 6)) != 0;
    if (d[0] & 0x3F) {
      fprintf(stderr, "Error: encountered EXFLAGS with reserved bits set. This probably means the\n");
      fprintf(stderr, "trace was generated with a newer hardware version than what's currently\n");
      fprintf(stderr, "supported.\n");
      return -1;
    }
  }
  
  // Scan trap data.
  if (packet->hasTrapped) {
    SCAN(9);
    packet->trapCause  = d[0];
    packet->trapPoint  = d[1];
    packet->trapPoint |= ((uint32_t)d[2]) << 8;
    packet->trapPoint |= ((uint32_t)d[3]) << 16;
    packet->trapPoint |= ((uint32_t)d[4]) << 24;
    packet->trapArg    = d[5];
    packet->trapArg   |= ((uint32_t)d[6]) << 8;
    packet->trapArg   |= ((uint32_t)d[7]) << 16;
    packet->trapArg   |= ((uint32_t)d[8]) << 24;
  }
  
  // Scan reconfiguration data.
  if (packet->hasNewConfiguration) {
    SCAN(4);
    packet->newConfiguration  = d[0];
    packet->newConfiguration |= ((uint32_t)d[1]) << 8;
    packet->newConfiguration |= ((uint32_t)d[2]) << 16;
    packet->newConfiguration |= ((uint32_t)d[3]) << 24;
  }
  
  // Scan optional zero-padding at the end of a cycle.
  while ((*rawDataRemain) && !(**rawDataPtr)) {
    (*rawDataRemain)--;
    (*rawDataPtr)++;
    endOfCycle = 1;
  }
  
  return endOfCycle ? 2 : 1;
  
}

/**
 * Decodes a cycle's worth of trace data for the given context. data->pc
 * should be 0 and data->config should be set to the initial configuration in
 * the first call to this method. Subsequent calls must be done using the same
 * data buffer, and the contents of the buffer should not be modified
 * externally. Returns 1 if successful, 0 if no more trace data is avalaible or
 * -1 if an error occured, in which case the error is printed to stderr.
 */
int getCycleInfo(
  uint8_t **rawDataPtr,
  int *rawDataRemain,
  int contextToTrace,
  cycle_data_t *data,
  int numLanes,
  int numGroups
) {
  
  uint32_t currentCfg = data->config;
  int i;
  
  // Reset valid flags.
  data->hasBranched = 0;
  data->hasTrapped = 0;
  data->hasNewConfiguration = 0;
  data->usedSlots = 0;
  for (i = 0; i < 16; i++) {
    data->slot[i].hasPC = 0;
    data->slot[i].hasMem = 0;
    data->slot[i].hasWrittenGP = 0;
    data->slot[i].hasWrittenLink = 0;
    data->slot[i].hasWrittenBranch = 0;
    data->slot[i].hasTrapped = 0;
    data->slot[i].hasNewConfiguration = 0;
  }
  
  // Read trace packets until we've found a full cycle's worth of data for the
  // context we're tracing.
  while (!data->usedSlots) {
    
    int lanesValid = 0;
    
    // Read the packets for the next cycle.
    while (1) {
      trace_packet_t packet;
      int endOfCycle;
      int slot;
      int i;
      
      // Read the next packet.
      endOfCycle = 0;
      switch (getTracePacket(rawDataPtr, rawDataRemain, &packet, numLanes)) {
        case -1:
          return -1;
        case 0:
          return 0;
        case 2:
          endOfCycle = 1;
      }
      
      // If there already is a packet for this lane, something went wrong.
      if (lanesValid && (1 << packet.lane)) {
        fprintf(stderr, "Error: multiple packets designated for the same lane encountered in the same\n");
        fprintf(stderr, "cycle. This could indicate that the number of lanes are not configured properly\n");
        fprintf(stderr, "on the command line.\n");
        return -1;
      }
      lanesValid |= 1 << packet.lane;
      
      // If the lane for this packet corresponds with the context which is
      // being traced, copy it to the right slot.
      slot = 0;
      for (i = 0; i < numLanes; i++) {
        int c = (currentCfg >> ((i / (numLanes / numGroups)) * 4)) & 0xF;
        if (i == packet.lane) {
          if (c == contextToTrace) {
            data->slot[slot] = packet;
            if (packet.hasPC) {
              if (data->usedSlots) {
                fprintf(stderr, "Error: PC was reported for multiple lanes within the same context.\n");
                return -1;
              }
              data->usedSlots = slot + 1;
              data->pc = (packet.pc & packet.hasPC) | (data->pc & ~packet.hasPC);
              data->hasBranched = packet.hasBranched;
            }
            if (packet.hasTrapped) {
              data->hasTrapped = packet.hasTrapped;
              data->trapPoint = packet.trapPoint;
              data->trapCause = packet.trapCause;
              data->trapArg = packet.trapArg;
            }
            if (packet.hasNewConfiguration) {
              data->hasNewConfiguration = 1;
              data->config = packet.newConfiguration;
            }
          }
          break;
        }
        if (c == contextToTrace) {
          slot++;
        }
      }
      
      // Break if the cycle end marker has been scanned.
      if (endOfCycle == 1) {
        break;
      }
      
    }
    
    if (data->hasNewConfiguration) {
      break;
    }
    
  }
  
  return 1;
  
}
