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
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>

#include "main.h"
#include "parser.h"
#include "types.h"

/**
 * Returns nonzero if the args specify a help command.
 */
static int isHelp(const commandLineArgs_t *args) {
  if (args->paramCount == 0) {
    return;
  }
  return !strcmp(args->params[0], "help");
}

/**
 * Performs the command specified by args.
 */
int run(commandLineArgs_t *args) {
  
  // --------------------------------------------------------------------------
  if (!strcmp(args->command, "select")) {
    int f;
    contextMask_t dummyMask;
    const char *ptr;
    int remain;
    
    if (isHelp(args) || (args->paramCount != 1)) {
      printf(
        "\n"
        "Command usage: rvd select \"<contexts>\"\n"
        "\n"
        "This command will set which rvex contexts will be addressed by future commands,\n"
        "which do not have a context explicitely specified through either the specific\n"
        "command, or the -c or --context command line parameters.\n"
        "\n"
        "<contexts> may be specified in any of the following ways (like any other context\n"
        "mask in rvd).\n"
        "\n"
        "  <int>         A single context is selected.\n"
        "  <int>..<int>  The specified context range is selected. The range specification\n"
        "                is inclusive; e.g. 0..3 specifies 4 contexts.\n"
        "  all           Context 0 up to _NUM_CONTEXTS are selected.\n"
        "\n"
        "The intended use for the contexts is to allow you to easily access multiple rvex\n"
        "processors/contexts, without needing to swap out the memory map file or having\n"
        "different definition names for each context. Technically you could define a\n"
        "completely different memory map for a different context though.\n"
        "\n"
        "When more than one context is selected, most rvd commands will simply execute\n"
        "sequentially for each context in the range. You can use this behavior to, for\n"
        "example, soft reset all contexts or stop execution of all contexts at roughly\n"
        "the same time.\n"
        "\n"
      );
      return 1;
    }
    
    // Syntax-check the context selection.
    if (parseMask(args->params[0], &dummyMask, "") < 1) {
      return 0;
    }
    
    // Write to the .rvd-context file.
    f = open(".rvd-context", O_WRONLY | O_CREAT);
    if (f < 0) {
      perror("Could not open .rvd-context for writing");
      return 0;
    }
    ptr = args->params[0];
    remain = strlen(ptr);
    while (remain) {
      int count = write(f, ptr, remain);
      if (count < 1) {
        perror("Could not write to .rvd-context");
        close(f);
        return 0;
      }
      ptr += count;
      remain -= count;
    }
    close(f);
    return 1;
    
  // --------------------------------------------------------------------------
  } else if ((!strcmp(args->command, "eval")) || (!strcmp(args->command, "evaluate"))) {
    value_t value;
    
    if (isHelp(args) || (args->paramCount != 1)) {
      printf(
        "\n"
        "Command usage: rvd evaluate \"<expression>\"\n"
        "\n"
        "This command will evaluate the given expression for the context(s) selected\n"
        "using \"rvd context\" or the -c or --context command line parameters.\n"
        "\n"
        "Call \"rvd help expressions\" for more information.\n"
        "\n"
      );
      return 1;
    }
    
    // TODO: do this for every context!
    
    // Evaluate the given command.
    if (evaluate(args->params[0], &value, "") < 1) {
      return 0;
    }
    
    // Display the result.
    switch (value.size) {
      case AS_BYTE:
        printf("0x%02lX = %lu\n", value.value & 0xFF, value.value & 0xFF);
        break;
        
      case AS_HALF:
        printf("0x%04lX = %lu\n", value.value & 0xFF, value.value & 0xFF);
        break;
        
      default:
        printf("0x%08lX = %lu\n", value.value, value.value);
        break;
        
    }
    
    return 1;
    
  // --------------------------------------------------------------------------
  } else if (!strcmp(args->command, "expressions")) {
    // (This is intentionally a help-only "command".)
    if (isHelp(args)) {
      printf(
        "\n"
        "How rvd expressions work\n"
        "------------------------\n"
        "\n"
        "Almost any integer specification in rvd - addresses, values, contexts, etc. -\n"
        "can be specified using expressions. An expression can be as simple as a number\n"
        "or as complex as a small script - it's a very basic functional scripting\n"
        "language.\n"
        "\n"
        "Integer literals\n"
        "----------------\n"
        "The most basic construct in an rvd expression is an integer literal. Literals\n"
        "can be specified like in C, meaning that the following things are all allowed.\n"
        "\n"
        "  <decimal>\n"
        "  0<octal>\n"
        "  0x<hexadecimal>\n"
        "  0b<binary>\n"
        "\n"
        "In addition to that, you can explicitely specify the type you want the literal\n"
        "to be by adding one of the following suffixes to the literal.\n"
        "\n"
        "  w   Word      32 bit\n"
        "  h   Halfword  16 bit\n"
        "  hh  Byte      8 bit\n"
        "\n"
        "The type used for a literal does not affect the ranges allowed. Or rather,\n"
        "there is no range checking anywhere, and everything is an unsigned 32-bit\n"
        "integer internally. However, the type is relevant when performing write\n"
        "operations: calling write(0, 0hh) will write a single byte to address 0,\n"
        "whereas write(0, 0w) will write a word to address 0.\n"
        "\n"
        "When no type is specified anywhere in the evaluation of an expression and type\n"
        "information is needed for evaluation, the type defaults to a word. When multiple\n"
        "explicitely specified types are used in an expression, the widest one is used.\n"
        "So, 1 + 1hh will evaluate to a byte with value 2, whereas 1w + 1hh will evaluate\n"
        "to a word.\n"
        "\n"
        "Operators\n"
        "---------\n"
        "rvd supports the following operators.\n"
        "\n"
        "  +   Addition\n"
        "  -   Subtraction or unary negation\n"
        "  *   Multiplication\n"
        "  /   Division\n"
        "  %   Modulo\n"
        "  <<  Left shift\n"
        "  >>  Right shift (logical)\n"
        "  ~   Unary one's complement\n"
        "  &   Bitwise and\n"
        "  |   Bitwise or\n"
        "  ^   Bitwise xor\n"
        "  ;   Sequential\n"
        "\n"
        "With the exception of the sequential operator, all operators behave the same as\n"
        "their C counterparts (applied to unsigned longs) on their own. However, THERE IS\n"
        "NO OPERATOR PRECEDENCE, and ALL OPERATORS ARE RIGHT ASSOCIATIVE. This means\n"
        "that, for example, 2 * 3 + 4 will be interpreted as 2 * (3 + 4) = 14, not\n"
        "(2 * 3) + 4 = 10. You should always use parenthesis when combining operators to\n"
        "make sure it will do what you want it to.\n"
        "\n"
        "The sequential operator will simply evaluate both sides sequentially, and pick\n"
        "the result of the rightmost operator.\n"
        "\n"
        "Definitions\n"
        "-----------\n"
        "The definition system is what makes expressions useful. An rvd expression\n"
        "behaves approximately like a C preprocessor definition: when an identifier\n"
        "is encountered in an expression which was previously defined, the defined\n"
        "expansion for the definition is evaluated as if it were an expression. This\n"
        "means that definitions can be used to define constants, as well as functions\n"
        "(without parameters).\n"
        "\n"
        "Definitions can be defined in the following ways.\n"
        "\n"
        " - Through a .map file.\n"
        " - Using the -d or --define command line parameters.\n"
        " - Dynamically within expressions, using the set() or def() functions.\n"
        "\n"
        "The syntax for a definition in a map file or on the command line looks like\n"
        "this:\n"
        "\n"
        "  <contexts> : <name> : <expression> .\n"
        "\n"
        "The <contexts> part specifies for which contexts the definition should be valid.\n"
        "Call \"rvd help select\" for more information; the syntax for <contexts> in the\n"
        "select command parameter is identical.\n"
        "\n"
        "<name> specifies the name for the definition. Names must start with an\n"
        "alphabetical character or an underscore, and may contain any combination of\n"
        "alphanumerical and underscores for the rest of the characters. Names are case\n"
        "sensitive. <expression> may specify any syntactically correct expression.\n"
        "\n"
        "The . (full stop) at the end of the definition is used as a seperator between\n"
        "multiple definitions, in particular within .map files. It is optional for the\n"
        "last (or only) definition in a list, though. Within .map files, anything between\n"
        "a # (hash) and a newline is a comment.\n"
        "\n"
        "The order in which definitions are defined does not matter, as long as\n"
        "everything is defined when the definition is used in an evaluated expression.\n"
        "This means loops are possible; when a certain number of expansions have been\n"
        "performed, however, parsing will terminate, to prevent hangs in this case.\n"
        "\n"
        "When definitions are defined dynamically using set() or def(), they are bound\n"
        "to the context currently being evaluated. This means that, for all intents and\n"
        "purporses, they behave like variables or dynamically created functions. The\n"
        "difference between set() and def() is that set() evaluates the given expression\n"
        "while set() as part of the set() command (making the definition behave like a\n"
        "variable), whereas def() defers evaluation until the definition is used (like\n"
        "a function).\n"
        "\n"
        "Functions\n"
        "---------\n"
        "In order for expression evaluation to actually do something, a number of\n"
        "built-in functions are made available. These are listed below.\n"
        "\n"
        "TODO\n"// TODO
        "\n"
      );
      return 1;
    }
  }
  
  // Unknown command.
  printf("Unknown command %s.\n", args->command);
  return 0;
  
}

