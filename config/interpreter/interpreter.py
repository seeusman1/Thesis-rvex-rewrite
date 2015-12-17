
def parse_file(fname, cmds):
    """Parses a file with syntax similar to LaTeX commands.
    
    Arguments:
     - fname specifies the file to read.
     - cmds needs to be a dictionary specifying the recognized commands. Each
       unrecognized command will be treated as documentation. The keys of the
       dictionary identify the command names. The entries are two-tuples, with
       the first entry stating the number of expected arguments and the second
       being a boolean which specifies if it is a group command. If the
       argument count of a recognized command is incorrect, an error will be
       shown.
      
    The return value is a list of dictionaries. These dicts have the following
    entries:
     - 'cmd': list with the following structure: [cmd_name, arg1, arg2, ...]
       Will be [''] for the first entry in the return value list.
     - 'subcmds': list of non-group commands in the previously described format.
     - 'doc': documentation text.
     - 'line_nr': group command line number
    
    Documentation and commands appearing before the first group command will be
    put in the first list in the result list. This contains the same entries
    as the other inner lists, but simply has an empty string as group command
    name and an empty list for the group arguments. Each group command will
    start a new entry in the result list.
    """
    with open(fname) as f:
        content = f.readlines()
    
    groups = [{
        'cmd': '',
        'subcmds': [],
        'doc': '',
        'line_nr': 1
    }]
    
    for line_nr_minus_one, line in enumerate(content):
        line_nr = line_nr_minus_one + 1
        
        # Ignore indentation, trailing whitespace and comments.
        line = line.split('%')[0].strip()
        
        # Ignore empty lines.
        if line == '':
            continue
        
        # Try to recognize commands.
        cmd_name = None
        cmd_data = None
        if line[0] == '\\':
            for cmd in cmds:
                if line.startswith('\\' + cmd):
                    cmd_name = cmd
                    cmd_data = cmds[cmd]
                    break
        
        # If we didn't recognize a command, handle as text.
        if cmd_data is None:
            groups[-1]['doc'] += line + '\n'
            continue
        
        # Scan the arguments of the command.
        args = []
        arg = ''
        depth = 0
        for c in line[len(cmd_name)+1:]:
            if c == '}':
                if depth == 0:
                    raise Exception('Unmatched } at ' +
                                    fname + ':' + str(line_nr))
                depth -= 1
                if depth == 0:
                    args += [arg]
                    arg = ''
            if depth > 0:
                arg += c
            if c == '{':
                depth += 1
        if depth > 0:
            raise Exception('Unmatched { at ' + fname + ':' + str(line_nr))
        if len(args) == 1:
            if args[0] == '':
                args = []
        if len(args) != cmd_data[0]:
            raise Exception('\\' + cmd_name + ' expects ' + str(cmd_data[0]) +
                            ' args but got ' + len(args) + ' at ' +
                            fname + ':' + str(line_nr))
        cmd = [cmd_name] + args
        
        # Handle the command.
        if cmd_data[1]:
            
            # Group command.
            groups += [{
                'cmd': cmd,
                'subcmds': [],
                'doc': '',
                'line_nr': line_nr
            }]
        
        else:
            
            # Handle other commands.
            groups[-1]['subcmds'] += [cmd]
        
    
    # Trim whitespace around the documentation entries.
    for group in groups:
        group['doc'] = group['doc'].strip()
    
    return groups


