
def generate(traps, dirs):
    traptable = traps['table']
    trapdoc = traps['doc']
    outfile = dirs['outdir'] + '/traps.generated.tex'
 
    # Start writing to the output file.
    with open(outfile, 'w') as f:
        f.write('\\newcounter{TrapCounter}\n')
        f.write('\\begin{itemize}\n')
        for doc in trapdoc:
            f.write('\\setcounter{enumi}{' + str(doc['traps'][0] - 1) + '}\n')
            for i, trap_id in enumerate(doc['traps']):
                if i > 0:
                    f.write('\\vskip -10 pt\\relax\n')
                trap = traptable[trap_id]
                f.write('\\item \\refstepcounter{TrapCounter} \\label{trap:%s} \\trap{%s} = 0x%02X\n' %
                        (trap['mnemonic'], trap['mnemonic'], trap_id))
            f.write('\\\\[6 pt]\n' + doc['doc'] + '\n\n')
        f.write('\\end{itemize}\n')
