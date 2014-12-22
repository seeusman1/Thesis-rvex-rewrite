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

#include "entry.h"
//#include "main.h"

/**
 * Prints usage information.
 */
static void usage(char *progName, int verbose);

/**
 * Prints license information.
 */
static void license(void);

/**
 * Application entry point.
 */
int main(int argc, char **argv) {
  
  commandLineArgs_t args;
  int i;
  
  // Set command line option defaults.
  args.port = 21079;
  args.mapFile = 0;
  
  // Parse command line arguments.
  while (1) {

    static struct option long_options[] = {
      {"port",     required_argument, 0, 'p'},
      {"map",      required_argument, 0, 'm'},
      {0, 0, 0, 0}
    };
    
    int option_index = 0;

    int c = getopt_long(argc, argv, "p:m:", long_options, &option_index);

    if (c == -1) {
      break;
    }

    switch (c) {
      case 'p':
        args.port = atoi(optarg);
        if ((args.port < 1) || (args.port > 65535)) {
          printf("%s: invalid TCP port specified\n\n", argv[0]);
          usage(argv[0], 0);
          exit(EXIT_FAILURE);
        }
        break;
        
      case 'm':
        args.mapFile = optarg;
        break;
        
      default:
        usage(argv[0], 0);
        exit(EXIT_FAILURE);
      
    }
  }
  
  // Don't crash if no command is specified.
  if (optind >= argc) {
    usage(argv[0], 0);
    exit(EXIT_FAILURE);
  }
  
  // Load the command and parameters count.
  args.command = argv[optind];
  args.params = (const char **)(argv + optind + 1);
  args.paramCount = argc - optind - 1;
  
  // Handle license and help commands.
  if (!strcmp(args.command, "help")) {
    if (args.paramCount > 0) {
      
      // Swap help and the command parameter around, so we can just handle
      // <command> help in run().
      args.command = args.params[0];
      args.params = (const char **)&"help";
      args.paramCount = 1;
      
    } else {
      
      // help without parameters; print usage and list commands.
      usage(argv[0], 1);
      exit(EXIT_SUCCESS);
      
    }
  } else if (!strcmp(args.command, "license")) {
    
    // Print license.
    license();
    exit(EXIT_SUCCESS);
    
  }
  
  // TODO
  
  // Exit.
  exit(EXIT_SUCCESS);
  
}

/**
 * Prints usage information.
 */
static void usage(char *progName, int verbose) {
  if (verbose) printf(
    "\n"
    "Debug interface for standalone r-VEX processor\n"
    "\n"
    "Copyright (C) 2008-2014 by TU Delft.\n"
    "All Rights Reserved.\n"
    "\n"
    "Run \"%s license\" for the full license.\n"
    "\n"
    "This program is used to send commands to the rvsrv daemon painlessly.\n",
    progName
  );
  printf(
    "\n"
    "Command line: %s [options] <command> [<params> ...]\n"
    "\n"
    "  -p  --port <port>  Specifies which TCP port to connect to. This should be the\n"
    "                     same as what was specified when starting rvsrv with the -d\n"
    "                     option. Defaults to port 21079.\n"
    "  -m  --map <file>   Specifies the memory map file to use. If not specified,\n"
    "                     only raw read/write commands are acceptable.\n"
    "\n",
    progName
  );
  if (!verbose) printf(
    "Run \"%s help\" for a command listing.\n"
    "\n",
    progName
  );
  if (verbose) printf(
    "Available commands:\n"
    "  help               Prints this listing.\n"
    "  license            Prints licensing information.\n"
    "\n"
    "Run \"%s help <command>\" for more information about a command, if available.\n"
    "\n",
    progName
  );
}

/**
 * Prints license information.
 */
static void license(void) {
  printf(
    "\n"
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
    "\n"
  );
}

