from __future__ import print_function

import common.templates
import code.type_sys
import opcode_table

def generate(opc, regs, trps, pl, dirs):
    
    header = []
    source = []
    
    hrule = '//' + '='*78 + '\n'
    separator = '\n' + hrule + '// %s\n' + hrule + '\n'
    
    # File headers.
    copyright = '\n'.join("""///
        // r-VEX simulator.
        //
        // Copyright (C) 2008-2015 by TU Delft.
        // All Rights Reserved.
        //
        // THIS IS A LEGAL DOCUMENT, BY USING r-VEX,
        // YOU ARE AGREEING TO THESE TERMS AND CONDITIONS.
        //
        // No portion of this work may be used by any commercial entity, or for any
        // commercial purpose, without the prior, written permission of TU Delft.
        // Nonprofit and noncommercial use is permitted as described below.
        //
        // 1. r-VEX is provided AS IS, with no warranty of any kind, express
        // or implied. The user of the code accepts full responsibility for the
        // application of the code and the use of any results.
        //
        // 2. Nonprofit and noncommercial use is encouraged. r-VEX may be
        // downloaded, compiled, synthesized, copied, and modified solely for nonprofit,
        // educational, noncommercial research, and noncommercial scholarship
        // purposes provided that this notice in its entirety accompanies all copies.
        // Copies of the modified software can be delivered to persons who use it
        // solely for nonprofit, educational, noncommercial research, and
        // noncommercial scholarship purposes provided that this notice in its
        // entirety accompanies all copies.
        //
        // 3. ALL COMMERCIAL USE, AND ALL USE BY FOR PROFIT ENTITIES, IS EXPRESSLY
        // PROHIBITED WITHOUT A LICENSE FROM TU Delft (J.S.S.M.Wong@tudelft.nl).
        //
        // 4. No nonprofit user may place any restrictions on the use of this software,
        // including as modified by the user, by any other authorized user.
        //
        // 5. Noncommercial and nonprofit users may distribute copies of r-VEX
        // in compiled or binary form as set forth in Section 2, provided that
        // either: (A) it is accompanied by the corresponding machine-readable source
        // code, or (B) it is accompanied by a written offer, with no time limit, to
        // give anyone a machine-readable copy of the corresponding source code in
        // return for reimbursement of the cost of distribution. This written offer
        // must permit verbatim duplication by anyone, or (C) it is distributed by
        // someone who received only the executable form, and is accompanied by a
        // copy of the written offer of source code.
        //
        // 6. r-VEX was developed by Stephan Wong, Thijs van As, Fakhar Anjam,
        // Roel Seedorf, Anthony Brandon, Jeroen van Straten. r-VEX is currently
        // maintained by TU Delft (J.S.S.M.Wong@tudelft.nl).
        //
        // Copyright (C) 2008-2015 by TU Delft.
        ///
        """.split('\n        '))
    header.append(copyright)
    header.append('\n'.join("""
        #ifndef RVSIM_COMPONENTS_CORE_GENERATED_H
        #define RVSIM_COMPONENTS_CORE_GENERATED_H

        #include <inttypes.h>

        namespace Core {

        """.split('\n        ')))
    source.append(copyright)
    source.append('\n'.join("""
        #include <cstdio>

        #include "Core.h"
        #include "CoreTypes.h"
        #include "Generated.h"

        using namespace std;

        namespace Core {

        """.split('\n        ')))
    
    # Language-agnostic code types.
    header.append(separator % 'Language-agnostic code types')
    header.append(code.type_sys.generate_c_typedefs())
    header.append('\n')
    
    # Opcode table.
    header.append(separator % 'Opcode decoding table')
    source.append(separator % 'Opcode decoding table')
    opcode_table.generate(opc, header, source)
    header.append('\n')
    source.append('\n')
    
    # Trap name definitions.
    header.append(separator % 'Traps')
    for index, trap in enumerate(trps['table']):
        if trap is None:
            continue
        header.append('#define TRAP_%s 0x%02X\n' % (trap['mnemonic'], index))
    header.append('\n')
    
    # Control register definitions in header file.
    header.append(separator % 'Control register definitions')
    for ent in regs['defs']:
        if ent[0] == 'reg':
            header.append('#define %s 0x%03X\n' % (ent[1], ent[3]))
        elif ent[0] == 'field':
            header.append('#define %s_BIT %d\n#define %s_MASK 0x%08X\n'
                % (ent[1], ent[2], ent[1], ent[3]))
    header.append('\n')
    
    # Pipeline stage definitions/
    header.append(separator % 'Pipeline definitions')
    for key in pl['defs']:
        header.append('#define %s %d\n' % (key, pl['defs'][key]))
    header.append('\n')
    
    # File footers.
    header.append('\n'.join("""
        } /* namespace Core */

        #endif
        """.split('\n        ')))
    source.append('\n'.join("""
        } /* namespace Core */
        """.split('\n        ')))
    
    # Write the files.
    common.templates.generate_raw(
        'c',
        dirs['outdir'] + '/Generated.h',
        ''.join(header))
    
    common.templates.generate_raw(
        'c',
        dirs['outdir'] + '/Generated.cpp',
        ''.join(source))
