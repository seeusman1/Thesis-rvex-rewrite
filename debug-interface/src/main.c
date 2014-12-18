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
#include <getopt.h>

/**
 * Prints usage information and exits.
 */
void usage(char *progName) {
  printf(
    "Interfacing program for rvex.periph_UART.vhd. This will drop you into a\n"
    "debugging environment
    "\n"
    "Usage: %s [options]\n"
    "\n"
    "-p  --port <port>    Specify serial port file to connect to. Defaults to\n"
    "                     /dev/ttyS0.\n"
    "-b  --baud <rate>    Specify baud rate to use. Defaults to 115200.\n"
    "-a  --app <port>     Listen on the specified TCP port for UART communication\n"
    "                     with application code. Defaults to port 21078.\n"
    "-d  --debug <port>   Listen on the specified TCP port for debugging commands.\n"
    "                     Defaults to port 21079.\n"
    "-r  --restrict       Block TCP connections which do not originate from\n"
    "                     127.0.0.1.\n"
    "-h  --help           Shows this usage screen.\n"
    "    --license        Prints licensing information.\n"
    "\n",
    progName
  );
  exit(1);
}

/**
 * Prints license information and exits.
 */
void license(void) {
  printf(
    "Debug interface for standalone r-VEX processor\n"
    "\n"
    "Copyright (C) 2008-2014 by TU Delft.\n"
    "All Rights Reserved.\n"
    "\n"
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
    "Copyright (C) 2008-2014 by TU Delft.\n"
  );
  exit(0);
}

/**
 * Application entry point.
 */
int main (int argc, char **argv) {
  
  // Set command line option defaults.
  int baudrate = 115200;
  char *port = "/dev/ttyS0";
  
  // Parse command line arguments.
  while (1) {

    static struct option long_options[] = {
      {"port",    required_argument, 0, 'p'},
      {"baud",    required_argument, 0, 'b'},
      {"help",    no_argument,       0, 'h'},
      {"license", no_argument,       0, 'l'},
      {0, 0, 0, 0}
    };
    
    int option_index = 0;

    int c = getopt_long(argc, argv, "p:b:h", long_options, &option_index);

    if (c == -1) {
      break;
    }

    switch (c) {
      case 0:
        break;

      case 'p':
        port = optarg;
        break;

      case 'b':
        baudrate = atoi(optarg);
        if (!baudrate) {
          printf("%s: invalid baud rate specified\n", argv[0]);
          usage(argv[0]);
        }
        break;

      case 'l':
        license();

      default:
        usage(argv[0]);
      
    }
  }
  
  // Print welcome text/license header.
  printf(
    "\n"
    "Debug interface for standalone r-VEX processor\n"
    "\n"
    "Copyright (C) 2008-2014 by TU Delft.\n"
    "All Rights Reserved.\n"
    "\n"
    "Run %s --license for the full license.\n"
    "\n",
    argv[0]
  );
  
  // TODO
  printf("Going to open serial port %s with baud rate %d at some point here.\n", port, baudrate);
  exit(0);
}
