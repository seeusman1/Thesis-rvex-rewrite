import re

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
        
        # Try to recognize commands.
        cmd_name = None
        cmd_data = None
        if line != '':
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
                            ' args but got ' + str(len(args)) + ' at ' +
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

def generate(s, values={'n': None}, default='$%s$'):
    """Replaces all instances of \<key in values>{<optional python code>}.
    
    Used for generating stuff in the configuration files, like lists of similar
    registers. The above command, usually \n{} is then replaced with something
    which makes sense based on context, i.e. on whether the list of similar
    stuff is expanded or collapsed. To collapse a list, set the value of the
    variable key name in values to None, it will then be replaced with the
    format() string set by default. Otherwise, the value of the variable will
    be expanded by default. The default may be overridden by embedding python
    code between the curly brackets. This python code must return a string and
    uses the values dictionary as locals.
    """
    for varname in values:
        var = values[varname]
        while True:
            s = re.split(r'\\' + varname + r'\{((?:[^\\\}]|\\.)*)\}', s, 1)
            if len(s) == 1:
                s = s[0]
                break
            if s[1] == '':
                if var is None:
                    s = s[0] + (default % varname) + s[2]
                else:
                    s = s[0] + str(var) + s[2]
            else:
                s = s[0] + eval(s[1], {}, values) + s[2]
    return s
    
