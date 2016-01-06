from __future__ import print_function

import common.interpreter
import common.bitfields
import copy
import pprint
interpreter = common.interpreter
bitfields = common.bitfields

def parse(indir):
    """Parses the traps .tex files.
    
    Arguments:
     - indir specifies the directory in which to look for .tex files.
      
    The return value is a dictionary.
    
    'table': a list with 256 entries, each containing a dictionary which
    describes a trap or None if no trap is defined. The index is the trap
    idenitifier. The entries of this dictionary are as follows.
     - 'mnemonic': the identifier of the trap.
     - 'description': the contents of the description command. Only \n{} is
       replaced in trapgen commands.
     - 'debug': if this key exists, this is a debug trap.
     - 'interrupt': if this key exists, this is an interrupt trap.
    
    'doc': a list of dictionaries, representing the \trap and \trapgen
    commands in the order in which they were specified. Each dictionary contains
    the following entries.
     - 'name': friendly name/title of the trap (group). \n{} is replaced with
       $n$.
     - 'doc': multiline LaTeX documentation of the trap (group). \n{} is
       replaced with $n$.
     - 'origin': the line number and filename on which the trap (group) was
       defined.
     - 'traps': list of trap identifiers (indexing in the first entry of the
       result) of associated traps.
    """
    
    # Parse the file.
    traps = interpreter.parse_files(indir, {
        'trap': (3, True),
        'trapgen': (4, True),
        'description': (1, False),
        'debug': (0, False),
        'interrupt': (0, False)
    })
    
    # Make a fixed entry for trap 0.
    traptable = [None] * 256
    traptable[0] = {
        'mnemonic': 'NONE',
        'description': 'none'
    }
    trapdoc = [{
        'name': 'Normal operation',
        'doc': """Trap cause 0 is reserved to indicate normal operation. When an 
\insn{RFI} instruction is executed, the trap cause register (cause field in 
\creg{CCR}) will be reset to 0, so an external debug system can always determine 
what a program is doing, unless nested traps are utilized.""",
        'origin': '-1',
        'traps': [0]
    }]
    
    # Read the specified traps.
    for trap in traps[1:]:
        try:
            if trap['cmd'][0] == 'trap':
                ns = [0]
                start_index = int(trap['cmd'][1].strip(), 0)
                mnemonic = trap['cmd'][2].strip()
                title = trap['cmd'][3].strip()
            elif trap['cmd'][0] == 'trapgen':
                ns = eval(trap['cmd'][1])
                start_index = int(trap['cmd'][2].strip(), 0)
                mnemonic = trap['cmd'][3].strip()
                title = trap['cmd'][3].strip()
            else:
                raise Exception('Internal error: unknown trap command ' +
                                trap['cmd'][0] + ' on line ' + trap['origin'])
        except ValueError:
            raise Exception('Start index could not be parsed on line ' +
                            trap['origin'])
        if start_index == 0:
            raise Exception('Trap index 0 is reserved for "no trap" on line ' +
                            + trap['origin'])
        
        # Insert the traps into the table.
        ids = []
        for n in ns:
            index = start_index + n
            if traptable[index] is not None:
                raise Exception('Multiple definitions for trap index ' +
                                str(index) + ', defined on line ' +
                                + trap['origin'])
            ids += [index]
            traptable[index] = {
                'mnemonic': mnemonic.replace('\\n{}', str(n))
            }
            for mod in trap['subcmds']:
                if mod[0] == 'description':
                    traptable[index]['description'] = mod[1].replace('\\n{}', str(n))
                elif mod[0] == 'debug':
                    traptable[index]['debug'] = 'debug'
                elif mod[0] == 'interrupt':
                    traptable[index]['interrupt'] = 'interrupt'
                else:
                    raise Exception('Internal error: unknown trap modifier ' +
                                    mod[0] + ' on line ' + trap['origin'])
        
        # Add documentation for this trap (group).
        trapdoc += [{
            'name': title.replace('\\n{}', '$n$'),
            'mnemonic': mnemonic.replace('\\n{}', '$n$'),
            'doc': trap['doc'].replace('\\n{}', '$n$'),
            'origin': trap['origin'],
            'traps': ids
        }]
    
    return {'table': traptable, 'doc': trapdoc}
