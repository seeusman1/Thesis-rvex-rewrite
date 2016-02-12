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
#include <getopt.h>
#include <unistd.h>
#include <fcntl.h>
#include <limits.h>
#include <errno.h>


#include "entry.h"
#include "main.h"
#include "disasParse.h"
#include "readFile.h"

/**
 * Prints usage information.
 */
static void usage(char *progName);

/**
 * Prints license information.
 */
static void license(void);

/**
 * Safe version of strtoul that checks for error conditions.
 * Exits on error instead of returning.
 */
static unsigned long int safeStrToUl(char *str);

/**
 * Application entry point.
 */
int main(int argc, char **argv)
{
  
  commandLineArgs_t args;
  char *progName = argv[0];
  char *outputFile = 0;
  char *traceFile = 0;
  char **disasFiles = 0;
  int disasCount = 0;
  unsigned long int *disasOffsets = 0;
  int offsetCount = 0;
  uint8_t *traceData = 0;
  int traceDataSize = 0;
  int ok = 1;
  
  // Set command line option defaults.
  args.numLanes      = 8;
  args.numLaneGroups = 4;
  args.context       = 0;
  args.initialCfg    = 0;
  args.outputFile    = STDOUT_FILENO;
  
  // Parse command line arguments.
  while (1) {

    static struct option long_options[] = {
      {"numlanes",   required_argument, 0, 'l'},
      {"numgroups",  required_argument, 0, 'g'},
      {"context",    required_argument, 0, 'c'},
      {"cfg",        required_argument, 0, 'C'},
      {"help",       no_argument,       0, 'h'},
      {"license",    no_argument,       0, 'L'},
      {"offset",     required_argument, 0, '@'},
      {0, 0, 0, 0}
    };
    
    int option_index = 0;
    int c = getopt_long(argc, argv, "o:l:g:c:@:h", long_options, &option_index);

    if (c == -1) {
      break;
    }

    switch (c) {
      case 'o':
        outputFile = optarg;
        break;
        
      case 'l':
        args.numLanes = atoi(optarg);
        if ((args.numLanes != 2) && (args.numLanes != 4) && (args.numLanes != 8) && (args.numLanes != 16)) {
          fprintf(stderr, "%s: invalid number of lanes specified; must be 2, 4, 8 or 16.\n", progName);
          exit(EXIT_FAILURE);
        }
        break;
        
      case 'g':
        args.numLaneGroups = atoi(optarg);
        if ((args.numLaneGroups != 1) && (args.numLaneGroups != 2) && (args.numLaneGroups != 4) && (args.numLaneGroups != 8)) {
          fprintf(stderr, "%s: invalid number of lane groups specified; must be 1, 2, 4 or 8.\n", progName);
          exit(EXIT_FAILURE);
        }
        break;
        
      case 'c':
        args.context = atoi(optarg);
        if ((args.context < 0) && (args.context > 8)) {
          fprintf(stderr, "%s: invalid context specified; must be between 0 and 7.\n", progName);
          exit(EXIT_FAILURE);
        }
        break;
        
      case 'C':

        args.initialCfg = safeStrToUl(optarg);
        break;

      case '@':
        disasOffsets = realloc(disasOffsets, (offsetCount + 1)*sizeof(unsigned long int));
        if (!disasOffsets)
        {
          fprintf(stderr, "realloc failed\n");
          exit(EXIT_FAILURE);
        }
        disasOffsets[offsetCount] = safeStrToUl(optarg);
        offsetCount++;
        break;
        
      case 'h':
        usage(progName);
        exit(EXIT_SUCCESS);
        
      case 'L':
        license();
        exit(EXIT_SUCCESS);
        
      default:
        usage(progName);
        exit(EXIT_FAILURE);
      
    }
  }
  
  // Check command line parameters.
  if (args.numLaneGroups >= args.numLanes) {
    fprintf(stderr, "%s: number of lane groups must be less than the number of lanes.\n", progName);
    exit(EXIT_FAILURE);
  }
  
  // Get rid of the program name and switch command line arguments.
  argv += optind;
  argc -= optind;
  
  // Load trace and disassembly filenames.
  if (argc > 0 )
      traceFile = argv[0];
  if (argc > 1)
  {
    int i;
    disasFiles = malloc((argc-1)*sizeof(char *));
    for (i = 1; i < argc; i++)
    {
      disasFiles[i-1] = argv[i];
    }
    disasCount = argc - 1;
    if (disasCount > offsetCount)
    {
      disasOffsets = realloc(disasOffsets, disasCount * sizeof(unsigned long int));
      if (!disasOffsets)
      {
        fprintf(stderr, "realloc failure\n");
        exit(EXIT_FAILURE);
      }
      for (i = offsetCount; i < disasCount; i++)
        disasOffsets[i] = 0;
    }
  }
  if (argc < 1)
  {
      usage(progName);
      exit(EXIT_FAILURE);
  }
  
  // Open output file for writing.
  if (ok && outputFile) {
    unlink(outputFile);
    args.outputFile = open(outputFile, O_WRONLY | O_CREAT, 00644);
    if (args.outputFile < 0) {
      perror("Failed to open output file for writing");
      ok = 0;
    }
  }
  
  // Load the trace data into memory.
  if (ok) {
    traceData = (uint8_t*)readFile(traceFile, &traceDataSize, 0);
    if (!traceData) {
      return -1;
    }
    args.traceData = traceData;
    args.traceDataSize = traceDataSize;
  }
  
  // Load disassembly data into memory.
  if (ok && disasFiles) {
    int i;
    for (i = 0; i < disasCount; i++) {
      if (disasLoad(disasFiles[i], disasOffsets[i]) < 0) {
        ok = 0;
      }
    }
  }
  
  // Parse and dump the trace data.
  if (ok) {
    if (run(&args)) {
      ok = 0;
    }
  }
  
  // Close output file, if there is one.
  if (args.outputFile && (args.outputFile != STDOUT_FILENO)) {
    close(args.outputFile);
  }
  
  // Clean up disassembly data structures.
  disasFree();
  
  // Clean up trace data.
  if (traceData) {
    free(traceData);
  }
  
  // Exit gracefully.
  exit(ok ? EXIT_SUCCESS : EXIT_FAILURE);
  
}

/**
 * Prints usage information.
 */
static void usage(char *progName) {
  fprintf(stderr, 
    "Usage: %s [options] <trace dump file> [disassembly file]\n"
    "\n"
    "Decodes a trace dump made using the \"rvd trace\" command.\n"
    "\n"
    "Options:\n"
    "\n"
    "  -c <context>    Specifies the context ID to dump the trace of. Defaults to 0.\n"
    "  -o <outfile>    Dump to <outfile> rather than stdout.\n"
    "  -l <count>      Specifies the number of lanes in the processor. Defaults to 8.\n"
    "  -g <count>      Number of lane groups in the processor. Defaults to 4.\n"
    "  --cfg <config>  Initial runtime configuration word.\n"
    "  -@ <number>     Offset for disasembly file. Can be given multiple times for\n"
    "                  multiple disasembly files.\n"
    "  -h or --help    Shows this usage screen.\n"
    "  --license       Prints licensing information.\n"
    "\n",
    progName
  );
}

/**
 * Prints license information.
 */
static void license(void) {
  fprintf(stderr, 
    "\n"
    "Debug interface for standalone r-VEX processor\n"
    "\n"
    "Copyright (C) 2008-2015 by TU Delft.\n"
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
    "Copyright (C) 2008-2015 by TU Delft.\n"
    "\n"
  );
}

/**
 * Safe version of strtoul that checks for error conditions.
 * Exits on error instead of returning.
 */
unsigned long int safeStrToUl(char *str)
{
  unsigned long int value = 0;
  char *endptr = 0;
  value = strtoul(str, &endptr, 0);
  if ((errno == ERANGE && (value == LONG_MAX || value == LONG_MIN))
      || (errno != 0 && value == 0)) {
    perror("strtol");
    exit(EXIT_FAILURE);
  }

  if (endptr == str) {
    fprintf(stderr, "No digits were found\n");
    exit(EXIT_FAILURE);
  }
  return value;
}
