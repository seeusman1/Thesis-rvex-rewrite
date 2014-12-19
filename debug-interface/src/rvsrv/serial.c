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
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#include <termios.h>
#include <unistd.h>

#include "serial.h"

/**
 * Opens a serial port. Negative return values indicate failure, with errno set
 * to identify the last error. Positive return values are a file descriptor for
 * the open port. The port is opened in blocking mode.
 */
int openSerial(const char *name, const int baud) {
  int f;
  struct termios cfg;
  speed_t speed;
  
  // Try to open the port.
  f = open(name, O_RDWR | O_NOCTTY);
  
  // If the result was negative, we couldn't open it.
  if (f < 0) {
    perror("Failed to open serial port");
    printf("Maybe the server is already running?");
    return -1;
  }
  
  // Retrieve the current serial port configuration.
  if (tcgetattr(f, &cfg)) {
    perror("Error while setting baud rate");
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
    perror("Error while setting baud rate");
    return -1;
  }
  
  // Commit the new configuration.
  if (tcsetattr(f, TCSAFLUSH, &cfg)) {
    perror("Error while setting baud rate");
    return -1;
  }
  
  // Return the file descriptor.
  printf("Successfully opened serial port %s with baud rate %d.\n", name, baud);
  return f;
  
}

/**
 * Closes a previously opened serial port.
 */
void closeSerial(int *f) {
  
  // Don't do anything if the file descriptor is 0.
  if (!*f) return;
  
  // Attempt to close the file.
  close(*f);
  
  // Set the descriptor to 0 now that we've at least tried to close it.
  *f = 0;
  
}

