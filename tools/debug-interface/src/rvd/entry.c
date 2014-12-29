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
#include <signal.h>

#include "entry.h"
#include "main.h"
#include "parser.h"
#include "definitions.h"
#include "readFile.h"

/**
 * Prints usage information.
 */
static void usage(char *progName, int verbose);

/**
 * Prints license information.
 */
static void license(void);

/**
 * Calls cleanup methods and exits with the specified code.
 */
static void cleanupAndExit(int code) {
  
  // Close the connection to rvsrv if it is open.
  rvsrv_close();
  
  // Clean up the definition hash map.
  defs_free();
  
  exit(code);
}

/**
 * Called by the SIGTERM signal.
 */
static void sigTermHandler(int signum) {
  cleanupAndExit(EXIT_FAILURE);
}

/**
 * Application entry point.
 */
int main(int argc, char **argv) {
  
  commandLineArgs_t args;
  int i;
  int contextSpecified = 0;
  char errorPrefix[1024];
  char *buf;
  int port;
  char *host;
  
  // Set command line option defaults.
  port = 21079;
  host = "127.0.0.1";
  args.contextMask = 1 << 0;
  
  // Set terminate signal handlers such that they will call the free methods.
  signal(SIGTERM, &sigTermHandler);
  
  // Parse command line arguments.
  while (1) {

    static struct option long_options[] = {
      {"port",     required_argument, 0, 'p'},
      {"host",     required_argument, 0, 'h'},
      {"map",      required_argument, 0, 'm'},
      {"define",   required_argument, 0, 'd'},
      {"context",  required_argument, 0, 'c'},
      {0, 0, 0, 0}
    };
    
    int option_index = 0;

    int c = getopt_long(argc, argv, "p:h:m:d:c:", long_options, &option_index);

    if (c == -1) {
      break;
    }

    switch (c) {
      case 'p':
        port = atoi(optarg);
        if ((port < 1) || (port > 65535)) {
          fprintf(stderr, "%s: invalid TCP port specified\n\n", argv[0]);
          usage(argv[0], 0);
          cleanupAndExit(EXIT_FAILURE);
        }
        break;
        
      case 'h':
        host = optarg;
        break;
        
      case 'm':
        sprintf(errorPrefix, " in file %s", optarg);
        if (parseDefs(buf = readFile(optarg, 0, 0), errorPrefix) != 1) {
          free(buf);
          cleanupAndExit(EXIT_FAILURE);
        }
        free(buf);
        break;
        
      case 'd':
        if (parseDefs(optarg, " on the command line") != 1) {
          cleanupAndExit(EXIT_FAILURE);
        }
        break;
        
      case 'c':
        contextSpecified = 1;
        if (parseMask(optarg, &(args.contextMask), " in command line") != 1) {
          cleanupAndExit(EXIT_FAILURE);
        }
        break;
        
      default:
        usage(argv[0], 0);
        cleanupAndExit(EXIT_FAILURE);
      
    }
  }
  
  // Don't crash if no command is specified.
  if (optind >= argc) {
    usage(argv[0], 0);
    cleanupAndExit(EXIT_FAILURE);
  }
  
  // Load the command and parameters count.
  args.command = argv[optind];
  args.params = (const char **)(argv + optind + 1);
  args.paramCount = argc - optind - 1;
  
  // Try to read the current context mask from ".rvd-context", except when this
  // is coindidentally a select command (in which case we don't want to show
  // the error message if .rvd-context was broken).
  if (!contextSpecified && strcmp(args.command, "select")) {
    char *buf = readFile(".rvd-context", 0, 1);
    if (buf) {
      char *ptr = buf;
      while (*ptr) {
        if (*ptr == '\n') {
          *ptr = 0;
          break;
        }
        *ptr++;
      }
      if (parseMask(buf, &(args.contextMask), " in .rvd-context") != 1) {
        fprintf(stderr,
          "Defaulting to context 0. You might want to run \"rvd select 0\" to get rid\n"
          "of this error message.\n"
        );
      }
      free(buf);
    }
  }
  
  // Handle license and help commands.
  if (!strcmp(args.command, "help")) {
    if (args.paramCount > 0) {
      static const char *helpParams[] = { "help" };
      
      // Swap help and the command parameter around, so we can just handle
      // <command> help in run().
      args.command = args.params[0];
      args.params = helpParams;
      args.paramCount = 1;
      
    } else {
      
      // help without parameters; print usage and list commands.
      usage(argv[0], 1);
      cleanupAndExit(EXIT_SUCCESS);
      
    }
  } else if (!strcmp(args.command, "license")) {
    
    // Print license.
    license();
    cleanupAndExit(EXIT_SUCCESS);
    
  }
  
  // Hand the host name and port number to the rvsrv unit. It will connect when
  // the first request is made.
  if (rvsrv_setup(host, port) < 0) {
    cleanupAndExit(EXIT_FAILURE);
  }
  
  // Try to execute the given command.
  if (run(&args) < 0) {
    cleanupAndExit(EXIT_FAILURE);
  }
  
  // Done.
  cleanupAndExit(EXIT_SUCCESS);
  
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
    "  -m  --map <file>   Loads a memory map file. refer to the comments in the\n"
    "                     default memory.map file for more information.\n"
    "  -d  --define <def> (Re)defines a definition. <def> must have the same format\n"
    "                     as a line in a memory map file.\n"
    "  -c  --context <c>  Specifies the context(s) to use. May be a single context\n"
    "                     between 0 and 31, a range specified using the <from>..<to>\n"
    "                     format, or \"all\" to select all contexts. If not\n"
    "                     specified, rvd will use the last set of contexts selected\n"
    "                     with the select command.\n"
    "\n",
    progName
  );
  if (!verbose) printf(
    "Run \"%s help\" for a command listing.\n"
    "\n",
    progName
  );
  if (verbose) printf(
    "Basic commands:\n"
    "  help                 Prints this listing.\n"
    "  license              Prints licensing information.\n"
    "  select               Selects the rvex context to access.\n"
    "  evaluate, eval       Evaluates the given expression.\n"
    "  execute, exec        Executes the given expression.\n"
    "  stop                 Sends the stop command to rvsrv.\n"
    "\n"
    "Memory access:\n"
    "  write, w             Writes a word, halfword or byte.\n"
    "  read, r              Reads one or more words, halfwords or bytes.\n"
    "  fill                 Fills an address range with the specified byte.\n"
    "  upload, up           Uploads an S-record or binary file.\n"
    "  download, dl         Downloads an S-record or binary file.\n"
    "\n"
    "Debugging:\n"
    "  break, b             Stops execution on the selected contexts.\n"
    "  step, s              Executes the next bundle and stops again.\n"
    "  resume, continue, c  Resumes execution on the selected contexts.\n"
    "  release              Releases debugging control.\n"
    "  reset, rst           Soft-resets the selected contexts.\n"
    "  state, ?             Dumps context state.\n"
    "\n"
    "Run \"%s help <command>\" for more information about a command, if available.\n"
    "Also, \"%s help expressions\" prints information on how you can express things\n"
    "in rvd.\n"
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

