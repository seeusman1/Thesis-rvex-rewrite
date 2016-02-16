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

#ifndef _PARSER_H_
#define _PARSER_H_

#include "types.h"

/**
 * Evaluates an expression. Returns 1 if successful, 0 on failure, or -1 when
 * a fatal error occurs. An error message is printed upon failure if
 * errorPrefix is non-null.
 * 
 * EBNF (approximate*):
 *   start       = expression
 *   expression  = operand 
 *               | (operand, operator, expression)
 *   operator    = "+" | "-" | "*" | "/" | "%"
 *               | "==" | "!=" | ">" | ">=" | "<" | "<=" 
 *               | "<<" | ">>", "&", "|", "^",
 *               | "&&", "||"
 *   operand     = ( ( "-" | "~" | "!" ), operand )
 *               | ( "(", expression, ")" )
 *               | ( "read", "(", expression, ")" )
 *               | ( "readByte", "(", expression, ")" )
 *               | ( "readHalf", "(", expression, ")" )
 *               | ( "readWord", "(", expression, ")" )
 *               | ( "write", "(", expression, ",", expression, ")" )
 *               | ( "writeByte", "(", expression, ",", expression, ")" )
 *               | ( "writeHalf", "(", expression, ",", expression, ")" )
 *               | ( "writeWord", "(", expression, ",", expression, ")" )
 *               | ( "printf", "(", C string literal, { ",", expression } , ")" )
 *               | ( "set", "(", definition, ",", expression, ")" )
 *               | ( "def", "(", definition, ",", expression, ")" )
 *               | ( "if", "(", definition, ",", expression, [ ",", expression, ] ")" )
 *               | ( "while", "(", definition, ",", expression, ")" )
 *               | definition
 *               | literal
 *   literal     = C integer literal, [ "w" | "h" | "hh" ]
 *   definition  = [ "_" | alpha ], { "_" | alpha | digit }
 * 
 * The operators behave the same as in C, but note that there is no operator
 * precedence and all operators are right associative, so spam brackets. The
 * semicolon operator is an exception; it allows two expressions to be executed
 * sequentially. The result of the semicolon operator is the result from the
 * second operand.
 * 
 * The optional "w", "h" and "hh" after an integer literal specify word,
 * halfword or byte access size for writes respectively. For all operators
 * except shifts and the semicolon, the widest access size is used in the
 * result. For shift operators, the resulting access size is that of the
 * first operator.
 * 
 * * Differences between EBNF and actual grammar:
 *   - The second expression in the operand-operator-expression rule is
 *     optional if the next character is a close parenthesis or the end of the
 *     string.
 *   - The length of the arg list in printf depends on the number of format
 *     specifiers in the format string.
 */
int evaluate(const char *str, value_t *value, const char *errorPrefix);

/**
 * Parses a context mask.
 * 
 * EBNF:
 *   start       = ( C integer literal, [ "..", C integer literal ] )
 *               | "all"
 */
int parseMask(const char *str, contextMask_t *mask, const char *errorPrefix);

/**
 * Parses and registers the given definition list. Anything between # and \n is
 * interpreted as comment.
 * 
 * EBNF:
 *   start       = { def }
 *   def         = mask, ":", definition, ":", expansion, "."
 *   mask        = ( C integer literal, [ "..", C integer literal ] )
 *               | "all"
 */
int parseDefs(char *str, const char *errorPrefix);

#endif
