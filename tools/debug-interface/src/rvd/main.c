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
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>

#include "main.h"
#include "parser.h"
#include "types.h"
#include "utils.h"
#include "srec.h"
#include "rvsrvInterface.h"
#include "commands/commands.h"

/**
 * Converts a filetype mnemonic into a filetype_t.
 */
filetype_t interpretFiletype(const char *filetype) {
  if (!strcmp(filetype, "srec")) return FT_SREC;
  if (!strcmp(filetype, "s"))    return FT_SREC;
  if (!strcmp(filetype, "bin"))  return FT_STRAIGHT;
  if (!strcmp(filetype, "b"))    return FT_STRAIGHT;
  return FT_UNKNOWN;
}

/**
 * Returns nonzero if the args specify a help command.
 */
int isHelp(const commandLineArgs_t *args) {
  if (args->paramCount == 0) {
    return 0;
  }
  return !strcmp(args->params[0], "help");
}

/**
 * Performs the command specified by args, muxing between the com_[command]
 * methods based on the command name.
 */
int run(commandLineArgs_t *args) {
  
  if (
    (!strcmp(args->command, "select"))
  ) {
    return runSelect(args);
    
  } else if (
    (!strcmp(args->command, "eval")) ||
    (!strcmp(args->command, "evaluate")) ||
    (!strcmp(args->command, "exec")) ||
    (!strcmp(args->command, "execute"))
  ) {
    return runEvaluate(args);
    
  } else if (
    (!strcmp(args->command, "stop"))
  ) {
    return runStop(args);
    
  } else if (
    (!strcmp(args->command, "write")) ||
    (!strcmp(args->command, "w"))
  ) {
    return runWrite(args);
    
  } else if (
    (!strcmp(args->command, "read")) ||
    (!strcmp(args->command, "r"))
  ) {
    return runRead(args);
    
  } else if (
    (!strcmp(args->command, "fill"))
  ) {
    return runFill(args);
    
  } else if (
    (!strcmp(args->command, "upload")) ||
    (!strcmp(args->command, "up"))
  ) {
    return runUpload(args);
    
  } else if (
    (!strcmp(args->command, "download")) ||
    (!strcmp(args->command, "dl"))
  ) {
    return runDownload(args);
    
  } else if (
    (!strcmp(args->command, "trace"))
  ) {
    return runTrace(args);
    
  } else if (
    (!strcmp(args->command, "break")) ||
    (!strcmp(args->command, "b")) ||
    (!strcmp(args->command, "step")) ||
    (!strcmp(args->command, "s")) ||
    (!strcmp(args->command, "resume")) ||
    (!strcmp(args->command, "continue")) ||
    (!strcmp(args->command, "c")) ||
    (!strcmp(args->command, "release")) ||
    (!strcmp(args->command, "reset")) ||
    (!strcmp(args->command, "rst")) ||
    (!strcmp(args->command, "state")) ||
    (!strcmp(args->command, "?"))
  ) {
    return runDebug(args);
    
  } else if (
    (!strcmp(args->command, "gdb")) ||
    (!strcmp(args->command, "gdb-debug"))
  ) {
    return runGdb(args);
    
  } else if (
    (!strcmp(args->command, "expressions"))
  ) {
    // (This is intentionally a help-only "command".)
    if (isHelp(args)) {
      printf(
        "\n"
        "How rvd expressions work\n"
        "------------------------\n"
        "\n"
        "Almost any integer specification in rvd - addresses, values, contexts, etc. -\n"
        "can be specified using expressions. An expression can be as simple as a number\n"
        "or as complex as a small script - it's a basic functional scripting language.\n"
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
        "  %%   Modulo\n"
        "  ==  Equality\n"
        "  !=  Non-equality\n"
        "  <   Less than\n"
        "  <=  Less than or equal\n"
        "  >   Greater than\n"
        "  >=  Greater than or equal\n"
        "  !   Logical not\n"
        "  &&  Logical and\n"
        "  ||  Logical or\n"
        "  ~   Unary one's complement\n"
        "  &   Bitwise and\n"
        "  |   Bitwise or\n"
        "  ^   Bitwise xor\n"
        "  <<  Left shift\n"
        "  >>  Right shift (unsigned)\n"
        "  ;   Sequential\n"
        "\n"
        "With the exception of the sequential operator, all operators behave the same as\n"
        "their C counterparts (applied to uint32_ts) on their own. However, THERE IS\n"
        "NO OPERATOR PRECEDENCE, and ALL OPERATORS ARE RIGHT ASSOCIATIVE. This means\n"
        "that, for example, 2 * 3 + 4 will be interpreted as 2 * (3 + 4) = 14, not\n"
        "(2 * 3) + 4 = 10. You should always use parenthesis when combining operators to\n"
        "make sure it will do what you want it to.\n"
        "\n"
        "The sequential operator will simply evaluate both sides sequentially, and pick\n"
        "the result of the rightmost operator. The second operand of this operator is\n"
        "optional when the operator is followed by a close parenthesis or the end of the\n"
        "parsed string, in which case the first operand result is returned, as if the\n"
        "semicolon was not there.\n"
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
        "  <contexts>: <name> { <expression> }\n"
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
        "Within .map files, anything between a # (hash) and a newline is a comment.\n"
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
        "Required definitions\n"
        "--------------------\n"
        "There are a few definitions which should always be defined, either in a memory\n"
        "map file or as a command line parameter. These are the following.\n"
        "\n"
        "  _ALWAYS        This is always executed once before rvd does its first hardware\n"
        "                 access. Can be used to set up banking based on the predefined\n"
        "                 _CUR_CONTEXT definition.\n"
        "\n"
        "  _NUM_CONTEXTS  This defines the number of contexts available. Should expand\n"
        "                 to the same value for all contexts.\n"
        "\n"
        "Functions\n"
        "---------\n"
        "In order for expression evaluation to actually do something, a number of\n"
        "built-in functions are made available. These are listed below.\n"
        "\n"
        "  read(address)\n"
        "  readByte(address)\n"
        "  readHalf(address)\n"
        "  readWord(address)\n"
        "    These functions initiate a volatile hardware read, returning the value read.\n"
        "    If any kind of error or a bus fault occurs, evaluation is terminated. read\n"
        "    is simply a synonym for readWord().\n"
        "\n"
        "  write(address, value)\n"
        "  writeByte(address, value)\n"
        "  writeHalf(address, value)\n"
        "  writeWord(address, value)\n"
        "    These functions initiate a volatile hardware write. They return the value\n"
        "    written. If any kind of error or a bus fault occurs, evaluation is\n"
        "    terminated. write() will choose its access size based upon the type attached\n"
        "    to value.\n"
        "\n"
        "  preload(address, byteCount)\n"
        "    Preloads the specified block of memory using bulk read commands. byteCount\n"
        "    may be at most 4096. The preloaded memory can be read using the read*Preload\n"
        "    commands. Using a bulk read is a lot faster than issuing many volatile reads\n"
        "    in a sequence, so the preload() function can be used to increase performance\n"
        "    when many consequitive addresses are read at the same time. Only one block\n"
        "    of memory can be preloaded at a time, so calling preload() will delete the\n"
        "    previous buffer. This can be used to invalidate the preload buffer, by\n"
        "    \"preloading\" a zero-byte block of memory.\n"
        "\n"
        "  readPreload(address)\n"
        "  readBytePreload(address)\n"
        "  readHalfPreload(address)\n"
        "  readWordPreload(address)\n"
        "    These functions behave the same as their non-preload counterparts, unless\n"
        "    the requested value exists in the preload buffer, in which case that value\n"
        "    is used in favor of querying the hardware.\n"
        "\n"
        "  printf(format, ...)\n"
        "    This method wraps part of the C printf method. Refer to C documentation on\n"
        "    how it works. The following specifiers are NOT allowed:\n"
        "      f F e E g G a A c s p n\n"
        "    Also, size modifiers should not be used. printf will always return 0.\n"
        "\n"
        "  def(name, expansion)\n"
        "  set(name, expression)\n"
        "    Defines a definition dynamically. def() will set the expansion to the given\n"
        "    expression without evaluating it, deferring evaluation until the definition\n"
        "    is used. This allows basic procedures to be defined. set() evaluated the\n"
        "    given expression and sets the expansion of the definition to that value.\n"
        "    def() will always return zero, set() will return the value which was set.\n"
        "\n"
        "  if(condition, command-if-true)\n"
        "  if(condition, command-if-true, command-if-false)\n"
        "    Allows conditional evaluation. condition is always evaluated. If it\n"
        "    evaluates to nonzero, command-if-true is evaluated, but command-if-false\n"
        "    (if specified) is not. When condition is evaluates to zero, the opposite\n"
        "    operation is performed. if() will return the result of the executed command,\n"
        "    or 0 if condition evaluated to zero and command-if-false was not specified.\n"
        "\n"
        "  while(condition, command)\n"
        "    Allows looping. While condition evaluates to nonzero, command is evaluated.\n"
        "    Obviously, condition will also be evaluated for every iteration. while()\n"
        "    returns the last evaluated value for command, or 0 if it has not been\n"
        "    evaluated.\n"
        "\n"
        "  prioritize(condition1, action1 [, condition2, action2 [, ...]])\n"
        "    Works like an if-elseif-elseif etc. chain. If condition1 evaluates to\n"
        "    nonzero, action1 is evaluated and returned. Otherwise, if condition2\n"
        "    evaluates to nonzero, action2 is evaluated and returned, etc.. If all\n"
        "    conditions evaluate to false, 0 is returned. Once a condition evaluates\n"
        "    to true, further conditions are no longer evaluated.\n"
        "\n"
        "  delay_ms(time)\n"
        "    Delays execution for the specified amount of milliseconds.\n"
        "\n"
      );
      return 0;
    }
  }
  
  // Unknown command.
  fprintf(stderr, "Unknown command %s.\n", args->command);
  return -1;
  
}

