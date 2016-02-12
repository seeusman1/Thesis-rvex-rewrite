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
#include <string.h>

#include "rsp-protocol.h"
#include "rsp-commands.h"
#include "rsp-breakpoints.h"
#include "../types.h"
#include "../parser.h"
#include "../definitions.h"
#include "../rvsrvInterface.h"

/**
 * Whether we're currently attached to a process.
 */
static int attached = 1;

/**
 * Matches the packet buffer against the given command string. Returns 1 if
 * there is a match, 0 otherwise.
 */
int matchCommand(const char *buf, int bufLen, const char *command) {
  while (1) {
    if (*command == 0) {
      return 1;
    }
    if (bufLen <= 0) {
      return 0;
    }
    if (*buf != *command) {
      return 0;
    }
    buf++;
    command++;
    bufLen--;
  }
  return 0;
}

/**
 * Wait for the target to halt execution, then send the stop reason reply.
 */
static int tgtWait(void) {
  value_t v;
  char buf[32];
  
  // If we're supposedly not attached, report that the thread has been killed?
  if (!attached) {
    return rsp_sendPacketStr("X09");
  }
  
  // Flush the transmit buffer, because this can potentially take a while.
  if (rsp_flushTx() < 0) {
    return -1;
  }
  
  // Evaluate the _WAIT command.
  if (evaluate("_WAIT", &v, "") < 1) {
    return -1;
  }
  
  // From the "rvd gdb help" documentation:
  // _WAIT should wait for the target to be halted. The value returned must
  // identify the reason for halting:
  //   0x0xx - program termination with exit code xx
  //   0x1xx - watchpoint xx
  //   0x200 - (software) breakpoint
  //   0x201 - single step trap
  //   0x202 - no trap (_BREAK set manually)
  if ((v.value < 0) || (v.value > 0x202)) {
    
    // Undefined.
    fprintf(stderr, "Error: _WAIT returned an illegal return code, 0x%08X.\n", v.value);
    return -1;
    
  } else if (v.value < 0x100) {
    
    // Program terminated.
    sprintf(buf, "W%02x", v.value);
    return rsp_sendPacketStr(buf);
    
  } else if (v.value < 0x200) {
    
    // Watchpoint/hardware breakpoint.
    // TODO
    return rsp_sendPacketStr("T05watch:0;");
    
  } else {
    return rsp_sendPacketStr("S05");
  }
  
}

/**
 * Processes incoming RSP packets from gdb. buf should be null terminated and
 * bufLen should be the number of bytes in the buffer without the trailing
 * null. However, bufLen may not be strlen(buf), because the buffer itself may
 * contain nulls as well. Returns 0 on success or -1 on failure; in the latter
 * case an error is printed to stderr.
 */
int rsp_handlePacket(char *buf, int bufLen) {
  value_t v;
  char strBuf[RVSRV_PAGE_SIZE*2+1];
  static unsigned char dataBuf[RVSRV_PAGE_SIZE];
  
  // Query supported features.
  if (matchCommand(buf, bufLen, "qSupported")) {
    return rsp_sendPacketStr("PacketSize=2000");
  }
  
  // Query whether we're attached to a process.
  if (matchCommand(buf, bufLen, "qAttached")) {
    if (attached) {
      return rsp_sendPacketStr("1");
    } else {
      return rsp_sendPacketStr("0");
    }
  }
  
  // gdb is querying us for symbol lookup requests. We don't need to do symbol
  // lookups, so we just return OK.
  if (matchCommand(buf, bufLen, "qSymbol")) {
    return rsp_sendPacketStr("OK");
  }
  
  // gdb is asking how to relocate the executable. We always just load at
  // address 0 for as far as gdb is concerned.
  if (matchCommand(buf, bufLen, "qOffsets")) {
    return rsp_sendPacketStr("Text=0;Data=0;Bss=0");
  }
  
  // Report that we support extended-remote.
  if (matchCommand(buf, bufLen, "!")) {
    return rsp_sendPacketStr("OK");
  }
  
  // Detach from the target.
  if (matchCommand(buf, bufLen, "D")) {
    attached = 0;
    if (evaluate("_RELEASE", &v, "") < 1) {
      return -1;
    }
    return rsp_sendPacketStr("OK");
  }
  
  // Select thread. We don't support this, but we still need to return OK if
  // all threads or any thread is selected.
  if (matchCommand(buf, bufLen, "H")) {
    if ((buf[1] != 'c') && (buf[1] != 'g')) {
      return rsp_sendPacketStr("");
    }
    if ((bufLen == 3) && (buf[2] == '0')) {
      return rsp_sendPacketStr("OK");
    }
    if ((bufLen == 4) && (buf[2] == '-') && (buf[3] == '1')) {
      return rsp_sendPacketStr("OK");
    }
    return rsp_sendPacketStr("");
  }
  
  // Query why we've stopped.
  if (matchCommand(buf, bufLen, "?")) {
    return tgtWait();
  }
  
  // Start new program command. We just reset the processor.
  if (matchCommand(buf, bufLen, "vRun")) {
    attached = 1;
    if (evaluate("_RESET", &v, "") < 1) {
      return -1;
    }
    return tgtWait();
  }
  
  // Kill the current program. No-op.
  if (matchCommand(buf, bufLen, "vKill")) {
    attached = 0;
    return rsp_sendPacketStr("OK");
  }
  
  // Attach to PID. There's no concept of process IDs, so return an error.
  if (matchCommand(buf, bufLen, "vAttach")) {
    return rsp_sendPacketStr("E01");
  }
  
  // Restart the current program.
  if (matchCommand(buf, bufLen, "R")) {
    if (evaluate("_RESET", &v, "") < 1) {
      return -1;
    }
    return rsp_sendPacketStr("");
  }
  
  // Step or continue execution.
  if (matchCommand(buf, bufLen, "c") || matchCommand(buf, bufLen, "s")) {
    if (bufLen > 1) {
      uint32_t jumpAddr = 0;
      if (sscanf(buf + 1, "%x", &jumpAddr) != 1) {
        return rsp_sendPacketStr("E01");
      }
      sprintf(strBuf, "0x%08X", jumpAddr);
      if (defs_register(0xFFFFFFFF, "_GDB_REG_VALUE", strBuf) < 0) {
        return -1;
      }
      if (evaluate("_GDB_REG_JMP", &v, "") < 1) {
        return -1;
      }
    }
    if (evaluate(matchCommand(buf, bufLen, "c") ? "_RESUME" : "_STEP", &v, "") < 1) {
      return -1;
    }
    return tgtWait();
  }
  
  // Read memory.
  if (matchCommand(buf, bufLen, "m")) {
    uint32_t addr, size, fault, remain;
    char *strPtr;
    unsigned char *dataPtr;
    
    // Read address and size from the command.
    if (sscanf(buf + 1, "%x,%x", &addr, &size) != 2) {
      return rsp_sendPacketStr("E01");
    }
    if (size > RVSRV_PAGE_SIZE) {
      return rsp_sendPacketStr("E01");
    }
    
    // Perform address translation.
    sprintf(strBuf, "0x%08X", addr);
    if (defs_register(0xFFFFFFFF, "_GDB_ADDR", strBuf) < 0) {
      return -1;
    }
    if (evaluate("_GDB_ADDR_R", &v, "") < 1) {
      return -1;
    }
    addr = v.value;
    
    // Perform the memory read.
    switch (rvsrv_readBulk(addr, dataBuf, size, &fault)) {
      case 0:
        return rsp_sendPacketStr("E01");
      case -1:
        return -1;
    }
    
    // Convert to hex digits for the RSP reply.
    remain = size;
    strPtr = strBuf;
    dataPtr = dataBuf;
    while (remain--) {
      sprintf(strPtr, "%02hhx", *dataPtr);
      strPtr += 2;
      dataPtr += 1;
    }
    return rsp_sendPacketStr(strBuf);
  }
  
  // Write memory.
  if (matchCommand(buf, bufLen, "M")) {
    uint32_t addr, size, fault, remain;
    char *strPtr;
    unsigned char *dataPtr;
    
    // Read address and size from the command.
    if (sscanf(buf + 1, "%x,%x", &addr, &size) != 2) {
      return rsp_sendPacketStr("E01");
    }
    if (size > RVSRV_PAGE_SIZE) {
      return rsp_sendPacketStr("E02");
    }
    
    // Read data from the command.
    remain = size;
    strPtr = strstr(buf, ":") + 1;
    if (!strPtr) {
      return rsp_sendPacketStr("E03");
    }
    dataPtr = dataBuf;
    while (remain--) {
      if (sscanf(strPtr, "%02hhx", dataPtr) != 1) {
        return rsp_sendPacketStr("E04");
      }
      strPtr += 2;
      dataPtr += 1;
    }
    
    // Perform address translation.
    sprintf(strBuf, "0x%08X", addr);
    if (defs_register(0xFFFFFFFF, "_GDB_ADDR", strBuf) < 0) {
      return -1;
    }
    if (evaluate("_GDB_ADDR_W", &v, "") < 1) {
      return -1;
    }
    addr = v.value;
    
    // Perform the write.
    switch (rvsrv_writeBulk(addr, dataBuf, size, &fault)) {
      case 0:
        return rsp_sendPacketStr("E05");
      case -1:
        return -1;
    }
    return rsp_sendPacketStr("OK");
  }
  
  // Query registers.
  if (matchCommand(buf, bufLen, "g")) {
    int numRegs, reg;
    char *strPtr;
    
    // Preload and determine register count.
    if (evaluate("_GDB_REG_PRE", &v, "") < 1) {
      return -1;
    }
    if (evaluate("_GDB_REG_NUM", &v, "") < 1) {
      return -1;
    }
    numRegs = v.value;
    if ((numRegs < 0) || (numRegs > RVSRV_PAGE_SIZE/4)) {
      fprintf(stderr, "Error: _GDB_REG_NUM returned a value greater than 1024, which is the max.\n");
      return -1;
    }
    
    // Load the registers.
    strPtr = strBuf;
    for (reg = 0; reg < numRegs; reg++) {
      char strBuf2[16];
      sprintf(strBuf2, "0x%08X", reg);
      if (defs_register(0xFFFFFFFF, "_GDB_REG_INDEX", strBuf2) < 0) {
        return -1;
      }
      if (evaluate("_GDB_REG_R", &v, "") < 1) {
        return -1;
      }
      switch (v.size) {
        case AS_BYTE:
          sprintf(strPtr, "%02x", v.value);
          strPtr += 2;
          break;
        case AS_HALF:
          sprintf(strPtr, "%04x", v.value);
          strPtr += 4;
          break;
        default:
          sprintf(strPtr, "%08x", v.value);
          strPtr += 8;
          break;
      }
    }
    
    // Send the RSP reply.
    return rsp_sendPacketStr(strBuf);
  }
  
  // Write register.
  if (matchCommand(buf, bufLen, "P")) {
    uint32_t reg, value;
    int numRegs;
    
    // Determine how many registers we have.
    if (evaluate("_GDB_REG_NUM", &v, "") < 1) {
      return -1;
    }
    numRegs = v.value;
    if ((numRegs < 0) || (numRegs > RVSRV_PAGE_SIZE/4)) {
      fprintf(stderr, "Error: _GDB_REG_NUM returned a value greater than 1024, which is the max.\n");
      return -1;
    }
    
    // Read register number and write value.
    if (sscanf(buf + 1, "%x=%x", &reg, &value) != 2) {
      return rsp_sendPacketStr("E01");
    }
    if (reg >= numRegs) {
      return rsp_sendPacketStr("E02");
    }
    
    // Define the register index and value for the memory map script.
    sprintf(strBuf, "0x%08X", reg);
    if (defs_register(0xFFFFFFFF, "_GDB_REG_INDEX", strBuf) < 0) {
      return -1;
    }
    sprintf(strBuf, "0x%08X", value);
    if (defs_register(0xFFFFFFFF, "_GDB_REG_VALUE", strBuf) < 0) {
      return -1;
    }
    
    // Execute the write.
    if (evaluate("_GDB_REG_W", &v, "") < 1) {
      return -1;
    }
    
    return rsp_sendPacketStr("OK");
  }
  
  // Set/remove breakpoint/watchpoint.
  if (matchCommand(buf, bufLen, "Z") || matchCommand(buf, bufLen, "z")) {
    uint32_t type, addr, kind;
    
    // Parse the breakpoint type, address and kind.
    if (sscanf(buf + 1, "%x,%x,%x", &type, &addr, &kind) != 3) {
      return rsp_sendPacketStr("E01");
    }
    if (type > 4) {
      return rsp_sendPacketStr("E02");
    }
    
    // Make sure there's no complicated condition/action stuff, which we don't
    // support.
    if (strstr(buf, ";")) {
      return rsp_sendPacketStr("E03");
    }
    
    // See if the value for kind is supported.
    if (type < 2) {
      if (kind != 4) {
        return rsp_sendPacketStr("E04");
      }
    } else {
      if ((kind != 4) && (kind != 2) && (kind != 1)) {
        return rsp_sendPacketStr("E05");
      }
    }
    
    // Update the breakpoint.
    switch (gdb_breakpoint((int)type, addr, buf[0] == 'Z')) {
      case 0:
        return rsp_sendPacketStr("E06");
      case 1:
        return rsp_sendPacketStr("OK");
      default:
        return -1;
    }
  }
  
  // Unsupported command, send empty packet in reply.
  return rsp_sendPacketStr("");
  
}

