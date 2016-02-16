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
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#include <termios.h>
#include <unistd.h>

#include "serial.h"
#include "select.h"

#define SERIAL_BUFFER_SIZE 256

// When this is defined, any characters sent or received on the raw,
// application or debug stream are logged to stdout/the log file.
//#define DEBUG_UART

/**
 * Control characters.
 */
#define CHAR_SEL_APP   0xFE
#define CHAR_SEL_DEBUG 0xFD
#define CHAR_ESCAPE    0xFC

/**
 * Defines the state of a ring buffer of size SERIAL_BUFFER_SIZE.
 */
typedef struct {
  
  short data[SERIAL_BUFFER_SIZE];
  int readPtr;
  int writePtr;
  int count;
  
} ringBuffer_t;

/**
 * Returns 1 if the specified buffer is full.
 */
static int ringBufFull(ringBuffer_t *buf) {
  return buf->count >= SERIAL_BUFFER_SIZE;
}

/**
 * Returns 1 if the specified buffer is empty.
 */
static int ringBufEmpty(ringBuffer_t *buf) {
  return buf->count == 0;
}

/**
 * Pushes a short into the ring buffer, if it is not full.
 */
static int ringBufPush(ringBuffer_t *buf, int data) {
  
  // Return -1 if buffer is full.
  if (ringBufFull(buf)) {
    return -1;
  }
  
  // Push a short.
  buf->data[buf->writePtr++] = data;
  if (buf->writePtr >= SERIAL_BUFFER_SIZE) {
    buf->writePtr = 0;
  }
  buf->count++;
  
  return 0;
}

/**
 * Pops a short from the ring buffer and returns it, or returns -1 if the
 * buffer is empty.
 */
static int ringBufPop(ringBuffer_t *buf) {
  short retval;
  
  // Return -1 if buffer is empty.
  if (ringBufEmpty(buf)) {
    return -1;
  }
  
  // Pop a short.
  retval = buf->data[buf->readPtr++];
  if (buf->readPtr >= SERIAL_BUFFER_SIZE) {
    buf->readPtr = 0;
  }
  buf->count--;
  
  return retval;
}

/**
 * Resets/initializes a ring buffer.
 */
static void ringBufReset(ringBuffer_t *buf) {
  buf->readPtr = 0;
  buf->writePtr = 0;
  buf->count = 0;
}

/**
 * Receive and transmit buffers for the application data bytestream. This only
 * contains byte values (0-255).
 */
static ringBuffer_t appRxBuf;
static ringBuffer_t appTxBuf;

/**
 * Receive and transmit buffers for debug data. Aside from 0-255 for normal
 * data bytes, values greater than 255 are used to delimit packets. The
 * receiving stream only inserts 256. For the transmitting stream, values
 * greater than 256 request that at least [value]-256 characters be sent before
 * the next debug packet completes, to give the expected hardware time to
 * finish transmitting the expected reply before it attempts to queue the next
 * reply (which would result in a dropped packet).
 */
static ringBuffer_t debugRxBuf;
static ringBuffer_t debugTxBuf;

/**
 * Opens a serial port. Negative return values indicate failure, with errno set
 * to identify the last error. Positive return values are a file descriptor for
 * the open port. The port is opened in blocking mode.
 */
int serial_open(const char *name, const int baud) {
  int f;
  struct termios cfg;
  speed_t speed;
  
  // Before anything else, initialize the ring buffers.
  ringBufReset(&appRxBuf);
  ringBufReset(&appTxBuf);
  ringBufReset(&debugRxBuf);
  ringBufReset(&debugTxBuf);
  
  // Try to open the port.
  f = open(name, O_RDWR | O_NOCTTY);
  
  // If the result was negative, we couldn't open it.
  if (f < 0) {
    perror("Failed to open serial port");
    printf("Maybe the server is already running?\n");
    return -1;
  }
  
  // Retrieve the current serial port configuration.
  if (tcgetattr(f, &cfg)) {
    perror("Error while setting baud rate (tcgetattr)");
    close(f);
    return -1;
  }
  
  // Make sure we're in raw mode.
  cfmakeraw(&cfg);
  
  // Set the speed.
  switch (baud) {
    case 50:      speed = B50;      break;
    case 75:      speed = B75;      break;
    case 110:     speed = B110;     break;
    case 134:     speed = B134;     break;
    case 150:     speed = B150;     break;
    case 200:     speed = B200;     break;
    case 300:     speed = B300;     break;
    case 600:     speed = B600;     break;
    case 1200:    speed = B1200;    break;
    case 1800:    speed = B1800;    break;
    case 2400:    speed = B2400;    break;
    case 4800:    speed = B4800;    break;
    case 9600:    speed = B9600;    break;
    case 19200:   speed = B19200;   break;
    case 38400:   speed = B38400;   break;
    case 57600:   speed = B57600;   break;
    case 115200:  speed = B115200;  break;
    case 230400:  speed = B230400;  break;
    case 460800:  speed = B460800;  break;
    
    default:
      printf("Error while setting baud rate: invalid baud rate\n");
      return -1;
      
  }
  if (cfsetispeed(&cfg, speed) || cfsetospeed(&cfg, speed)) {
    perror("Error while setting baud rate (cfset*speed)");
    close(f);
    return -1;
  }
  
  // Commit the new configuration.
  if (tcsetattr(f, TCSAFLUSH, &cfg)) {
    perror("Error while setting baud rate (tcsetattr)");
    close(f);
    return -1;
  }
  
  // Register with select_wait().
  if (select_register(f) < 0) {
    close(f);
    return -1;
  }
  
  // Return the file descriptor.
  printf("Successfully opened serial port %s with baud rate %d.\n", name, baud);
  return f;
  
}

/**
 * Closes a previously opened serial port.
 */
void serial_close(int *f) {
  
  // Don't do anything if the file descriptor is negative.
  if (*f < 0) return;
  
  // Unregister from select_wait().
  select_unregister(*f);
  
  // Attempt to close the file.
  close(*f);
  
  // Set the descriptor to -1 now that we've at least tried to close it.
  *f = -1;
  
}

/**
 * Updates the serial port after a call to select_wait(). Reads data from the
 * port into our buffer.
 */
int serial_update(int f) {

  // Raw receive buffer. This is used in the raw read() call, after which all
  // data is pushed into the app and debug receive buffers. It may take more
  // than one call to update to clear this buffer if appRxBuf or debugRxBuf
  // are full.
  static unsigned char buf[SERIAL_BUFFER_SIZE];
  static int bufSize = 0;
  static int bufPtr = 0;
  
  // Set to 0 when the application stream is selected, set to 1 when the debug
  // stream is selected.
  static int stream = 0;
  
  // When nonzero, the next byte should be one's complemented because an escape
  // character was received.
  static int escaping = 0;
  
  // This is set when the last character written to the debug stream was the
  // special delimiter character (256).
  static int debugPacketTerminated = 1;
  
  // If the raw buffer is ready for new data and data is available, pull new
  // data into it.
  if ((select_isReady(f)) && (bufPtr >= bufSize)) {
    
    // Reset the (fully drained) buffer.
    bufPtr = 0;
    
    // Read into the buffer.
    bufSize = read(f, (void*)buf, SERIAL_BUFFER_SIZE);
    if (bufSize < 0) {
      perror("Failed to read from serial port");
      return -1;
    } else if (bufSize == 0) {
      printf("Failed to read from serial port: reached end of file\n");
      return -1;
    }
    
    // Unregister from select_wait() while the buffer is full.
    select_unregister(f);
  
  }
  
  // Route raw data into the application and debug bytestreams if possible.
  for (; bufPtr < bufSize; bufPtr++) {
    short b = buf[bufPtr];
    
#ifdef DEBUG_UART
    printf("rx %02hhX\n", b);
#endif
    
    // Stop if either destination buffer is full.
    if (ringBufFull(&appRxBuf) || ringBufFull(&debugRxBuf)) {
      break;
    }
    
    if (b == CHAR_SEL_APP) {
      
      // Switch to application stream.
      if (!debugPacketTerminated) {
        ringBufPush(&debugRxBuf, 256);
        debugPacketTerminated = 1;
      }
      stream = 0;
      continue;
      
    } else if (b == CHAR_SEL_DEBUG) {
      
      // Switch to debug stream.
      if (!debugPacketTerminated) {
        ringBufPush(&debugRxBuf, 256);
        debugPacketTerminated = 1;
      }
      stream = 1;
      continue;
      
    } else if (b == CHAR_ESCAPE) {
      
      // Set escaping flag and continue.
      escaping = 1;
      continue;
      
    }
    if (escaping) {
      
      // Handle the escape flag.
      escaping = 0;
      b = (~b) & 0xFF;
      
    }
    if (stream == 0) {
      
      // Push into the application stream.
      ringBufPush(&appRxBuf, b);
      
    } else {
      
      // Push into the debug stream.
      ringBufPush(&debugRxBuf, b);
      debugPacketTerminated = 0;
      
    }
    
  }
  
  // Re-register with select_wait() if the buffer has been cleared.
  if (bufPtr >= bufSize) {
    select_register(f);
  }
  
  return 0;
  
}

/**
 * Writes a byte to the serial port, buffering it as long as there's room.
 */
static int bufferedWriteRaw(int f, int data) {
  
  // Raw transmit buffer.
  static unsigned char buf[SERIAL_BUFFER_SIZE];
  static int bufSize = 0;
  
  // See if we need to flush before we can append the byte or if a flush has
  // been explicitely requested.
  if ((bufSize >= SERIAL_BUFFER_SIZE) || (data < 0)) {
    int idx = 0;
    while (idx < bufSize) {
      int amount;
      
      // Write to the serial port.
      amount = write(f, buf + idx, bufSize - idx);
      if (amount < 0) {
        perror("Could not write to serial port");
        return -1;
      }
      
      idx += amount;
    }
    bufSize = 0;
  }
  
  // Append the byte to the buffer.
  if (data >= 0) {
#ifdef DEBUG_UART
    printf("tx %02hhX\n", data);
#endif
    buf[bufSize++] = data;
  }
  
  return 0;
}

/**
 * Writes a data byte to the serial port, escaping it if needed.
 */
static int bufferedWriteData(int f, int data) {
  
  data &= 0xFF;
  
  // Send escape character and one's complement byte if needed.
  if ((data == CHAR_SEL_APP) || (data == CHAR_SEL_DEBUG) || (data == CHAR_ESCAPE)) {
    if (bufferedWriteRaw(f, CHAR_ESCAPE) < 0) {
      return -1;
    }
    data = (~data) & 0xFF;
  }
  
  // Send the data byte.
  if (bufferedWriteRaw(f, data) < 0) {
    return -1;
  }
  
  return 0;
}

/**
 * Writes all pending data in the transmit buffers to the serial port.
 */
int serial_flush(int f) {
  
  // We can hardcode the packet buffer size to 32 because the hardware has the
  // same constraint.
  static unsigned char packetBuf[32];
  static int packetBufSize = 0;
  static int packetBufDelay = 0;
  static int packetReady = 0;
  
  // At least this many characters need to be sent before the next debug packet
  // can begin. Note that this is all rather approximate; we can't trivially
  // predict how much we're going to send and it doesn't need to be exact.
  static int delay = 0;
  
  // Set to 0 when the application stream is selected, set to 1 when the debug
  // stream is selected.
  static int stream = 0;
  
  while (!ringBufEmpty(&appTxBuf) || !ringBufEmpty(&debugTxBuf)) {
    
    // Read into the packet buffer.
    while (!ringBufEmpty(&debugTxBuf) && !packetReady) {
      
      int d = ringBufPop(&debugTxBuf);
      
      if (d < 256) {
        
        // Append byte to packet buffer.
        if (packetBufSize < 32) {
          packetBuf[packetBufSize] = d;
        }
        packetBufSize++;
        
      } else {
        if (packetBufSize <= 32) {
          
          // Queue packet.
          packetBufDelay = d - 256;
          packetReady = 1;
          
          // Sending the packet will take at least as many characters as the
          // unescaped packet payload, plus one for the start-packet marker,
          // so we can subtract this from the delay.
          delay -= packetBufSize + 1;
          if (delay < 0) delay = 0;
          
        } else {
          
          // Discard packet, because it's too long. This shouldn't happen.
          printf("Error: tried to send a packet which is too large for the hardware to handle, dropped it.\n");
          packetBufSize = 0;
          
        }
      }
      
    }
    
    // Send application bytes either as padding or because no more debug
    // packets are available.
    while (!ringBufEmpty(&appTxBuf) && (delay || !packetReady)) {
    
      // First switch to the application stream if necessary.
      if (stream != 0) {
        if (bufferedWriteRaw(f, CHAR_SEL_APP) < 0) {
          return -1;
        }
        stream = 0;
        
        // We've sent a byte, so subtract 1 from the delay.
        delay--;
        if (delay < 0) delay = 0;
      }
      
      // Send a byte.
      if (bufferedWriteData(f, ringBufPop(&appTxBuf)) < 0) {
        return -1;
      }
      
      // We've sent a byte, so subtract 1 from the delay.
      delay--;
      if (delay < 0) delay = 0;
      
    }
    
    // Send the queued packet.
    if (packetReady) {
      int i;
      
      // If we still need to delay at this point, our only option is to send
      // pad bytes. We can do that with the select-application-stream control
      // characters, because they're no-op when not followed 
      while (packetReady && delay) {
        
        if (bufferedWriteRaw(f, CHAR_SEL_APP) < 0) {
          return -1;
        }
        stream = 0;
        delay--;
        if (delay < 0) delay = 0;
        
      }
      
      // Send the packet start marker.
      if (stream != 1) {
        if (bufferedWriteRaw(f, CHAR_SEL_DEBUG) < 0) {
          return -1;
        }
        stream = 1;
      }
      
      // Send the packet.
      for (i = 0; i < packetBufSize; i++) {
        
        if (bufferedWriteData(f, packetBuf[i]) < 0) {
          return -1;
        }
        
      }
      
      // Set the delay and clear the packet queued marker.
      delay = packetBufDelay;
      packetReady = 0;
      packetBufSize = 0;
      
      // If there are more bytes in the debug buffer, assume that we're going
      // to be sending another debug packet soon. Otherwise, switch to the
      // application stream (we need to do something here so the hardware knows
      // that a complete packet has been received).
      if (!ringBufEmpty(&debugTxBuf)) {
        if (bufferedWriteRaw(f, CHAR_SEL_DEBUG) < 0) {
          return -1;
        }
        stream = 1;
      } else {
        if (bufferedWriteRaw(f, CHAR_SEL_APP) < 0) {
          return -1;
        }
        stream = 0;
      }
      delay--;
      if (delay < 0) delay = 0;
      
    }
    
  }
  
  // Flush the transmit buffer.
  bufferedWriteRaw(f, -1);
  
  return 0;
  
}

/**
 * Returns a byte from the application receive FIFO, or -1 if the FIFO is empty.
 */
int serial_appReceive(int f) {
  int data;
  
  // Return -1 if the buffer is empty.
  if (ringBufEmpty(&appRxBuf)) {
    return -1;
  }
  
  // Return the popped byte.
  data = ringBufPop(&appRxBuf);
  data &= 0xFF;
#ifdef DEBUG_UART
  printf("rxa %02hhX\n", data);
#endif
  return data;
  
}

/**
 * Pushes a byte onto the application transmit buffer.
 */
int serial_appSend(int f, int data) {
  
#ifdef DEBUG_UART
  printf("txa %02hhX\n", data);
#endif
  
  // Flush if the buffer is full.
  if (ringBufFull(&appTxBuf)) {
    if (serial_flush(f) < 0) {
      return -1;
    }
  }
  
  // Push the byte into the buffer.
  ringBufPush(&appTxBuf, data & 0xFF);
  
  return 0;
}

/**
 * Returns a byte from the debug receive FIFO, or -1 if the FIFO is empty. 256
 * is returned as a packet delimiter.
 */
int serial_debugReceive(int f) {
  int data;
  
  // Return -1 if the buffer is empty.
  if (ringBufEmpty(&debugRxBuf)) {
    return -1;
  }
  
  // Return the popped byte.
  data = ringBufPop(&debugRxBuf);
#ifdef DEBUG_UART
  printf("rxd %02hhX\n", data);
#endif
  return data;
  
}

/**
 * Pushes a byte onto the debug transmit buffer when data lies between 0 and
 * 255, or pushes a packet delimiter when data is greater than or equal to
 * 256. In the latter case, the serial unit will ensure that at least
 * data-256 bytes are sent before the next packet completes, to give the
 * hardware time to send the reply.
 */
int serial_debugSend(int f, int data) {
  
#ifdef DEBUG_UART
  printf("txd %02hhX\n", data);
#endif
  
  // Flush if the buffer is full.
  if (ringBufFull(&debugTxBuf)) {
    if (serial_flush(f) < 0) {
      return -1;
    }
  }
  
  // Push the byte into the buffer.
  ringBufPush(&debugTxBuf, data);
  
  return 0;
}

