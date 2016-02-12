from __future__ import print_function

import common.bitfields
bitfields = common.bitfields

def generate(regs, dirs):
    regmap = regs['regmap']
    regdoc = regs['regdoc']
    globoutfile = dirs['outdir'] + '/gbreg.generated.tex'
    ctxtoutfile = dirs['outdir'] + '/cxreg.generated.tex'

    # Write the output files.
    output_file(globoutfile, regmap, regdoc, 'glob')
    output_file(ctxtoutfile, regmap, regdoc, 'ctxt')

def print_reg_head(f, wrap=False):
    f.write('\\vskip -10 pt\\relax\\noindent\\footnotesize\n')
    f.write('\\begin{' + ('longtable' if wrap else 'tabular') + '}{@{}p{12mm}@{}*{32}{p{3.4mm}@{}}p{24mm}@{}}\n')
    f.write((' &' * 33) + ' \\\\\n')
    s = '\\multicolumn{1}{@{}l@{}|}{\\scriptsize Offset \\ } & '
    for bit in reversed(range(32)):
        s += '\\multicolumn{1}{@{}c@{}' + ('|' if (bit % 8) == 0 else '') + '}{\\tiny' + str(bit) + '} & '
    f.write(s + '\\\\\n\\cline{2-33}\n')
    if wrap:
        f.write('\\endhead\n\\cline{2-33}\n\\endfoot\n')

def print_reg_row(f, reg):
    s = '\\multicolumn{1}{@{}l@{}|}{\\footnotesize \\texttt{0x%03X}} & ' % reg['offset']
    for field in reg['fields']:
        bcnt = field['upper_bit'] - field['lower_bit'] + 1
        #size = '\\tiny' if len(field['name']) >= bcnt else '\\footnotesize'
        size = '\\tiny'
        s += '\\multicolumn{' + str(bcnt) + '}{@{}c@{}|}{' + size + ' ' + field['name'] + '} & '
    s += '\\hspace{0.6 mm} \\normalsize\\creg{' + reg['mnemonic'] + '}\\footnotesize \\\\\n'
    s += '\\cline{2-33}\n'
    f.write(s)

def print_empty_row(f, offset):
    if offset is None:
        offset = '...'
    else:
        offset = '0x%03X' % offset
    s = '\\multicolumn{1}{@{}l@{}|}{\\footnotesize \\texttt{' + offset + '}} & '
    s += '\\multicolumn{32}{@{}c@{}|}{\\tiny\\textit{Unused}} & \\\\\n'
    s += '\\cline{2-33}\n'
    f.write(s)

def print_reg_detail(f, rowname, values):
    s = '\\multicolumn{1}{@{}l@{}}{\\scriptsize \\hfill ' + rowname + ' \\ } & '
    for value in reversed(values):
        s += '\\multicolumn{1}{@{}c@{}}{\\tiny' + value + '} & '
    f.write(s + '\\\\\n')
    
def print_reg_details(f, reg):
    reset = [''] * 32
    core  = [''] * 32
    debug = [''] * 32
    for field in reg['fields']:
        if 'reset' in field:
            resets = field['reset']
        else:
            resets = '0' * (field['upper_bit'] - field['lower_bit'] + 1)
        bit = field['upper_bit']
        for r in resets:
            reset[bit] = r
            core[bit] = '\\ding{51}' if 'core' in field else ''
            debug[bit] = '\\ding{51}' if 'debug' in field else ''
            bit -= 1
    print_reg_detail(f, 'Reset', reset)
    print_reg_detail(f, 'Core', core)
    print_reg_detail(f, 'Debug', debug)

def print_reg_foot(f, wrap=False):
    f.write('\\end{' + ('longtable' if wrap else 'tabular') + '}\n\\normalsize\\vskip 6pt\n')

def output_file(outfile, regmap, regdoc, regtype):
    with open(outfile, 'w') as f:
        
        # Print the register table.
        print_reg_head(f, True)
        num_empty = -1
        for word_offset, reg in enumerate(regmap):
            byte_offset = word_offset * 4
            if reg is None or regtype not in reg:
                if num_empty != -1:
                    num_empty += 1
                continue
            if num_empty == 1:
                print_empty_row(f, byte_offset - 4)
            elif num_empty > 1:
                print_empty_row(f, None)
            num_empty = 0
            print_reg_row(f, reg)
        print_reg_foot(f, True)
        
        # Print the documentation for each register.
        for doc in regdoc:
            if regtype not in doc:
                continue
            
            # Section header and labels.
            f.write('\\subsubsection[CR\_' + doc['mnemonic'] + ' - ' + doc['title'] + ']')
            f.write('{\\code{CR_' + doc['mnemonic'] + '} - ' + doc['title'] + '}\n')
            for reg in doc['registers']:
                f.write('\\label{reg:' + reg['mnemonic'] + '}\n')
            f.write('\\label{reg:' + doc['mnemonic'] + '}\n')
            
            # Print the register field table.
            print_reg_head(f)
            for reg in doc['registers']:
                print_reg_row(f, reg)
            print_reg_details(f, doc)
            print_reg_foot(f)
            
            # Print the register documentation.
            if doc['doc'] != '':
                f.write('\\noindent ' + doc['doc'] + '\n')
            
            # Print the field documentation.
            for field in doc['fields']:
                if field['name'] == '':
                    continue
                if field['doc'] == '':
                    continue
                if field['upper_bit'] == field['lower_bit']:
                    f.write('\\paragraph*{' + field['name'] + ' flag, bit ' +
                        str(field['upper_bit']))
                else:
                    f.write('\\paragraph*{' + field['name'] + ' field, bits ' +
                        str(field['upper_bit']) + '..' + str(field['lower_bit']))
                if len(field['alt_ids']) > 0:
                    f.write(', a.k.a. \\creg{' + '}, \\creg{'.join(field['alt_ids']) + '}')
                f.write('}\n')
                for alt_id in field['alt_ids']:
                    f.write('\\label{reg:' + alt_id + '}\n')
                f.write(field['doc'] + '\n')

