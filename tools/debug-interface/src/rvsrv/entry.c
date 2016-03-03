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
#include <string.h>
#include <getopt.h>
#include <sys/stat.h>

#include "entry.h"
#include "main.h"

/**
 * Prints usage information.
 */
static void usage(char *progName, int verbose);

/**
 * Prints the welcome message.
 */
static void welcome(void);

/**
 * Prints license information.
 */
static void license(void);

/**
 * Application entry point.
 */
int main(int argc, char **argv) {
  
  commandLineArgs_t args;
  
  // Set command line option defaults.
  args.port = "/dev/ttyS0";
  args.baudrate  = 115200;
  args.pcieCdev = NULL;
  args.mmioFile = NULL;
  args.mmioOffset = 0;
  args.mmioLength = 0;
  args.appPort   = 21078;
  args.debugPort = 21079;
  args.foreground = 0;
  args.noReconnect = 0;
  
  // Parse command line arguments.
  while (1) {

    static struct option long_options[] = {
      {"port",         required_argument, 0, 'p'},
      {"baud",         required_argument, 0, 'b'},
      {"pcie",         required_argument, 0, 'P'},
      {"mmio",         required_argument, 0, 'm'},
      {"app",          required_argument, 0, 'a'},
      {"debug",        required_argument, 0, 'd'},
      {"foreground",   no_argument,       0, 'f'},
      {"help",         no_argument,       0, 'h'},
      {"license",      no_argument,       0, 'l'},
      {"no-reconnect", no_argument,       0, 'n'},
      {0, 0, 0, 0}
    };
    
    int option_index = 0;

    int c = getopt_long(argc, argv, "p:b:P:m:a:d:h", long_options, &option_index);

    if (c == -1) {
      break;
    }

    switch (c) {
      case 'p':
        args.port = optarg;
        break;
        
      case 'b':
        args.baudrate = atoi(optarg);
        if (args.baudrate < 1) {
          printf("%s: invalid baud rate specified\n\n", argv[0]);
          usage(argv[0], 0);
          exit(EXIT_FAILURE);
        }
        break;

      case 'P':
        args.pcieCdev = optarg;
        {
          struct stat st;
          if (stat(args.pcieCdev, &st) == -1) {
            printf("%s: Couldn't stat PCIe character device %s.\n", argv[0],
                args.pcieCdev);
            perror(argv[0]);
            printf("\n");
            usage(argv[0], 0);
            exit(EXIT_FAILURE);
          } else if (!S_ISCHR(st.st_mode)) {
            printf("%s: Path doesn't point to a character device: %s.\n\n", argv[0],
                args.pcieCdev);
            usage(argv[0], 0);
            exit(EXIT_FAILURE);
          }
        }
        break;
        
      case 'm':
        {
          char *token;
          
          // Parse filename.
          token = strtok(optarg, ":");
          if (token == NULL) {
            printf("%s: --mmio syntax is malformed.\n\n", argv[0]);
            usage(argv[0], 0);
            exit(EXIT_FAILURE);
          }
          args.mmioFile = token;
          
          // Parse offset.
          token = strtok(NULL, ":");
          if (token == NULL) {
            printf("%s: --mmio syntax is malformed.\n\n", argv[0]);
            usage(argv[0], 0);
            exit(EXIT_FAILURE);
          }
          args.mmioOffset = strtoul(token, NULL, 0);
          
          // Parse length.
          token = strtok(NULL, ":");
          if (token == NULL) {
            printf("%s: --mmio syntax is malformed.\n\n", argv[0]);
            usage(argv[0], 0);
            exit(EXIT_FAILURE);
          }
          args.mmioLength = strtoul(token, NULL, 0);
          
        }
        break;
        
      case 'a':
        args.appPort = atoi(optarg);
        if ((args.appPort < 1) || (args.appPort > 65535)) {
          printf("%s: invalid TCP port specified for application access\n\n", argv[0]);
          usage(argv[0], 0);
          exit(EXIT_FAILURE);
        }
        break;
        
      case 'd':
        args.debugPort = atoi(optarg);
        if ((args.debugPort < 1) || (args.debugPort > 65535)) {
          printf("%s: invalid TCP port specified for debug access\n\n", argv[0]);
          usage(argv[0], 0);
          exit(EXIT_FAILURE);
        }
        break;
        
      case 'f':
        args.foreground = 1;
        break;
        
      case 'n':
        args.noReconnect = 1;
        break;
        
      case 'l':
        welcome();
        license();
        exit(EXIT_SUCCESS);
        
      case 'h':
        welcome();
        usage(argv[0], 1);
        exit(EXIT_SUCCESS);
        
      default:
        usage(argv[0], 0);
        exit(EXIT_FAILURE);
      
    }
  }
  
  // Make sure the application and debug ports are not set to the same port.
  if (args.appPort == args.debugPort) {
    printf("%s: cannot use one port for both application and debug interface\n\n", argv[0]);
    usage(argv[0], 0);
    exit(EXIT_FAILURE);
  }
  
  // Make sure that the user isn't trying to do PCIe and mmio at the same time.
  if (args.mmioFile && args.pcieCdev) {
    printf("%s: cannot use PCIe and memory mapped I/O at the same time\n\n", argv[0]);
    usage(argv[0], 0);
    exit(EXIT_FAILURE);
  }
  
  // Print welcome text/license header.
  welcome();
  printf("Run %s --license for the full license.\n\n", argv[0]);
  
  // Command line parsing and eye candy complete: now run the actual program.
  if (run(&args)) {
    exit(EXIT_FAILURE);
  }
  
  // Exit gracefully.
  printf("Shut down gracefully.\n");
  exit(EXIT_SUCCESS);
  
}

/**
 * Prints usage information.
 */
static void usage(char *progName, int verbose) {
  if (verbose) printf(
    "Interfacing program for rvex.periph_UART.vhd. This program will listen on\n"
    "two TCP ports for incoming connections. One port (21078 by default) is for\n"
    "communication with the running application: any incoming data is forwarded\n"
    "to the FIFO accessible through the slave bus interface, and any data sent\n"
    "by that interface (through puts(), printf() etc.) is broadcast to all\n"
    "connected clients. The other port (21078 by default) listens to debug\n"
    "commands.\n"
    "\n"
  );
  printf(
    "Command line: %s [options]\n"
    "\n"
    "  -p  --port <port>  Specify serial port file to connect to. Defaults to\n"
    "                     /dev/ttyS0.\n"
    "  -b  --baud <rate>  Specify baud rate to use. Defaults to 115200.\n"
    "  -P  --pcie <dev>   Use the PCIe driver to communicate with the device instead\n"
    "                     of the UART connection. Specify the character device to use\n"
    "                     to communicate with the driver.\n"
    "  -m  --mmio <d>:<s>:<l>  Use memory-mapped I/O to communicate with the device\n"
    "                     instead of the UART connection. <d> should be a device\n"
    "                     filename, <s> should be an offset within the device file\n"
    "                     and <l> should be the number of bytes to map.\n"
    "  -a  --app <port>   Listen on the specified TCP port for UART communication\n"
    "                     with application code. Defaults to port 21078.\n"
    "  -d  --debug <port> Listen on the specified TCP port for debugging commands.\n"
    "                     Defaults to port 21079.\n"
    "      --foreground   Run in the calling terminal instead of starting the daemon\n"
    "                     process.\n"
    "      --no-reconnect Do not attempt to reconnect to serial port after the port\n"
    "                     stops working; exit instead.\n"
    "  -h  --help         Shows this usage screen%s.\n"
    "      --license      Prints licensing information.\n"
    "\n",
    progName, verbose ? "" : "with some extra info"
  );
}

/**
 * Prints the welcome message.
 */
static void welcome(void) {
  printf(
    "\n"
    "Debug interface for standalone r-VEX processor\n"
    "\n"
    "Copyright (C) 2008-2015 by TU Delft.\n"
    "All Rights Reserved.\n"
    "\n"
  );
}

/**
 * Prints license information.
 */
static void license(void) {
  printf(
    "THIS IS A LEGAL DOCUMENT, BY USING r-VEX,\n"
    "YOU ARE AGREEING TO THESE TERMS AND CONDITIONS.\n"
    "\n"
    "No portion of this work may be used by any commercial entity, or for any\n"
    "commercial purpose, without the prior, written permission of TU Delft.\n"
    "Nonprofit and noncommercial use is permitted as described below.\n"
    "\n"
    "1. r-VEX is provided AS IS, with no warranty of any kind, express\n"
    "or implied. The user of the code accepts full responsibility for the\n"
    "application of the code and the use of any results.\n"
    "\n"
    "2. Nonprofit and noncommercial use is encouraged. r-VEX may be\n"
    "downloaded, compiled, synthesized, copied, and modified solely for nonprofit,\n"
    "educational, noncommercial research, and noncommercial scholarship\n"
    "purposes provided that this notice in its entirety accompanies all copies.\n"
    "Copies of the modified software can be delivered to persons who use it\n"
    "solely for nonprofit, educational, noncommercial research, and\n"
    "noncommercial scholarship purposes provided that this notice in its\n"
    "entirety accompanies all copies.\n"
    "\n"
    "3. ALL COMMERCIAL USE, AND ALL USE BY FOR PROFIT ENTITIES, IS EXPRESSLY\n"
    "PROHIBITED WITHOUT A LICENSE FROM TU Delft (J.S.S.M.Wong@tudelft.nl).\n"
    "\n"
    "4. No nonprofit user may place any restrictions on the use of this software,\n"
    "including as modified by the user, by any other authorized user.\n"
    "\n"
    "5. Noncommercial and nonprofit users may distribute copies of r-VEX\n"
    "in compiled or binary form as set forth in Section 2, provided that\n"
    "either: (A) it is accompanied by the corresponding machine-readable source\n"
    "code, or (B) it is accompanied by a written offer, with no time limit, to\n"
    "give anyone a machine-readable copy of the corresponding source code in\n"
    "return for reimbursement of the cost of distribution. This written offer\n"
    "must permit verbatim duplication by anyone, or (C) it is distributed by\n"
    "someone who received only the executable form, and is accompanied by a\n"
    "copy of the written offer of source code.\n"
    "\n"
    "6. r-VEX was developed by Stephan Wong, Thijs van As, Fakhar Anjam,\n"
    "Roel Seedorf, Anthony Brandon, Jeroen van Straten. r-VEX is currently\n"
    "maintained by TU Delft (J.S.S.M.Wong@tudelft.nl).\n"
    "\n"
    "Copyright (C) 2008-2015 by TU Delft.\n"
    "\n"
  );
}

