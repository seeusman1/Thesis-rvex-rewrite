from __future__ import print_function

from sys import argv
from sys import exit
import opcodes
import common.bitfields
bitfields = common.bitfields

def generate(opc, dirs):
    # Parse the opcode configuration file.
    sections       = opc['sections']
    table          = opc['table']
    def_params     = opc['def_params']
    stats_outfile  = dirs['outdir'] + '/opcode-stats.generated.tex'
    table_outfile  = dirs['outdir'] + '/opcode-table.generated.tex'
    doc_outfile    = dirs['outdir'] + '/opcode-docs.generated.tex'
    vexasm_outfile = dirs['outdir'] + '/vexasm.generated.tex'

    # Generate the table. While doing so, count the number of instructions and the
    # number of free opcodes.
    insn_count = 0
    free_opcode_count = 0
    with open(table_outfile, 'w') as f:
        hori_line = '\\cline{1-32}\n'
        
        # longtable header.
        f.write('\\footnotesize\n')
        f.write('\\begin{longtable}{*{32}{@{}p{3mm}}@{}l@{}}\n')
        f.write((' &' * 32) + ' \\\\\n')
        f.write(bitfields.format_tex_head() + ' & \\\\\n')
        f.write(hori_line)
        f.write('\\endhead\n')
        f.write(hori_line)
        f.write('\\endfoot\n')
        
        # Iterate over all opcodes to print the corresponding instruction.
        prev_syl = None
        for opc, syl in enumerate(table):
            
            # Ignore unused opcodes.
            if syl is None:
                free_opcode_count += 1
                continue
            
            # Skip over repeats of instructions which use multiple opcodes.
            if prev_syl is syl:
                continue
            prev_syl = syl
            
            # Iterate over the imm_sw options for this instruction.
            for imm_sw in opcodes.get_imm_sw(syl):
                f.write(bitfields.format_tex(opcodes.get_bitfields(syl, imm_sw)))
                f.write(' & \hyperref[opc:%s]{\\color{codeInlineColor}\\tiny{\\texttt{\\detokenize{ %s}}}}\\\\\n' % (
                    syl['name'], opcodes.format_syntax(syl['syntax'], 'plain', syl, imm_sw)))
                f.write(hori_line)
                insn_count += 1
            
        # longtable footer.
        f.write('\\end{longtable}\n')
        f.write('\\normalsize\\vskip 6pt\n')
    
    # Generate the file containing just the number of instructions.
    with open(stats_outfile, 'w') as f:
        f.write('\\newcommand{\\instructioncount}{' + str(insn_count) + '}\n')
        f.write('\\newcommand{\\freeopcodecount}{' + str(free_opcode_count) + '}\n')
    
    # Generate the instruction documentation.
    with open(doc_outfile, 'w') as f:
        f.write('\\newcounter{InstructionCounter}\n')
        
        labels = set()
        for section in sections:
            
            # Write the section header and documentation.
            f.write('\\insndocsection{' + section['name'] + '}\n' + section['doc'] + '\n')
            
            # Iterate over the instructions in this section.
            for syl in section['syllables']:
                imm_sws = opcodes.get_imm_sw(syl)
                
                f.write('\\vskip 10pt\n')
                f.write('\\noindent\\begin{minipage}{\\textwidth}\n')
                
                # Write the label.
                if syl['name'] not in labels:
                    labels.add(syl['name'])
                    f.write('\\refstepcounter{InstructionCounter}\\label{opc:' + syl['name'] + '}\n')
                
                # Write the syntax of the instruction as the title.
                for imm_sw in imm_sws:
                    f.write('\\noindent\\textbf{\\footnotesize\\texttt{\\detokenize{%s}}}\n\n' % (
                        opcodes.format_syntax(syl['syntax'], 'plain', syl, imm_sw)))
                
                # Write the encoding table.
                f.write('\\noindent\\footnotesize\n')
                f.write('\\begin{tabular}{*{32}{@{}p{0.03125 \\textwidth}}@{}}\n')
                f.write((' &' * 31) + ' \\\\\n')
                f.write(bitfields.format_tex_head() + '\\\\\n')
                f.write('\\cline{1-32}\n')
                for imm_sw in imm_sws:
                    f.write(bitfields.format_tex(opcodes.get_bitfields(syl, imm_sw)) + '\\\\\n')
                    f.write('\\cline{1-32}\n')
                f.write('\\end{tabular}\n')
                f.write('\\normalsize\n')
                f.write('\\end{minipage}\\vskip 10pt\n')
                
                # Write the documentation section.
                doc_imm_sw = imm_sws[0]
                if len(imm_sws) == 2:
                    doc_imm_sw = None
                f.write('\\noindent ' + opcodes.format_syntax(syl['doc'], 'plain', syl, doc_imm_sw))
                f.write('\n\n')
    
    # Generate the header file which generates a LaTeX listings language for
    # VEX assembly.
    with open(vexasm_outfile, 'w') as f:
        output = ['\lstdefinelanguage{vexasm}{morekeywords={']
        for opc, syl in enumerate(table):
            if syl is None:
                continue
            output.append(syl['name'])
            output.append(',')
        output[-1] = '},sensitive=false}\n'
        f.write(''.join(output))
    
    