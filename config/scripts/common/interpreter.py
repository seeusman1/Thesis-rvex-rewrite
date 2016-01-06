import re
import os
import copy

def parse_files(indir, cmds):
    """Parses all .tex files in a directory (as if they were concatenated
    alphabetically), with syntax similar to LaTeX commands.
    
    Arguments:
     - indir specifies the directory to search.
     - cmds needs to be a dictionary specifying the recognized commands. Each
       unrecognized command will be treated as documentation. The keys of the
       dictionary identify the command names. The entries are tuples, with
       the first entry stating the number of expected arguments and the second
       being a boolean which specifies if it is a group command. A third entry
       optionally specifies a dictionary with flags. If the argument count of a
       recognized command is incorrect, an error will be shown.
    
    The return value is a list of dictionaries. These dicts have the following
    entries:
     - 'cmd': list with the following structure: [cmd_name, arg1, arg2, ...]
       Will be [''] for the first entry in the return value list, see below.
     - 'subcmds': list of non-group commands in the previously described format.
     - 'doc': documentation text.
     - 'code': only if the 'code' flag is specified for a group command. This
       contains a list of two-tuples, each representing a line of code. The
       first entry of the tuple identifies the origin of the line, the second
       specifies the contents of the line.
     - 'origin': group command filename and line number.
    
    Documentation and commands appearing before the first group command will be
    put in the first list in the result list. This contains the same entries
    as the other inner lists, but simply has an empty string as group command
    name and an empty list for the group arguments. Each group command will
    start a new entry in the result list.
    """
    
    files = [f for f in os.listdir(indir)
        if os.path.isfile(os.path.join(indir, f))
        and f.endswith('.tex')]
    files.sort()
    
    content = []
    for fname in files:
        with open(os.path.join(indir, fname)) as f:
            fcontent = f.readlines()
        for i in range(len(fcontent)):
            fcontent[i] = (fname + ':' + str(i+1), fcontent[i])
        content += fcontent
    
    groups = [{
        'cmd': '',
        'subcmds': [],
        'doc': '',
        'origin': 'unknown'
    }]
    
    groupflags = {}
    for origin, cline in content:
        
        # Ignore indentation, trailing whitespace and comments.
        cline = cline.split('%')[0].rstrip()
        line = cline.strip()
        
        # Try to recognize commands.
        cmd_name = None
        cmd_data = None
        if line != '':
            if line[0] == '\\':
                for cmd in cmds:
                    if line.startswith('\\' + cmd):
                        if cmd_name is None or len(cmd) > len(cmd_name):
                            cmd_name = cmd
                            cmd_data = cmds[cmd]
        
        # If we didn't recognize a command, handle as text or code.
        if cmd_data is None:
            if 'code' in groupflags:
                groups[-1]['code'] += [(origin, cline)]
            else:
                groups[-1]['doc'] += cline + '\n'
            continue
        
        # Scan the arguments of the command.
        args = []
        arg = ''
        depth = 0
        for c in line[len(cmd_name)+1:]:
            if c == '}':
                if depth == 0:
                    raise Exception('Unmatched } at ' + origin)
                depth -= 1
                if depth == 0:
                    args += [arg]
                    arg = ''
            if depth > 0:
                arg += c
            if c == '{':
                depth += 1
        if depth > 0:
            raise Exception('Unmatched { at ' + origin)
        if len(args) == 1:
            if args[0] == '':
                args = []
        if len(args) != cmd_data[0]:
            raise Exception('\\' + cmd_name + ' expects ' + str(cmd_data[0]) +
                            ' args but got ' + str(len(args)) + ' at ' + origin)
        cmd = [cmd_name] + args
        
        # Handle the command.
        if cmd_data[1]:
            
            # Group command. Handle group flags if specified.
            if len(cmd_data) >= 3:
                groupflags = cmd_data[2]
            else:
                groupflags = {}
        
            # Add the group.
            group = {
                'cmd': cmd,
                'subcmds': [],
                'doc': '',
                'origin': origin
            }
            if 'code' in groupflags:
                group['code'] = []
            groups += [group]
            
        else:
            
            # Handle other commands.
            groups[-1]['subcmds'] += [cmd]
        
    
    # Trim whitespace around the documentation entries.
    for group in groups:
        group['doc'] = group['doc'].strip()
    
    return groups

def hierarchy(groups, hierarchy):
    """Applies a hierarchical structure to a parsed file.
    
    groups has the same format as the output of parse_files. hierarchy must be
    a list of two-tuples. Each two-tuple contains two lists, the first listing
    parent command names, and the second listing child command names with a
    multiplicity character appended:
    
        ? -> zero times or once
        ! -> exactly once
        * -> zero or more times
        + -> one or more times
    
    The order in which commands are specified is left alone. The parent command 
    name specification of the first two-tuple is ignored, and the child commands
    are interpreted as the acceptable top-level commands.
    
    When there is ambiguity in which ancestor a subcommand belongs to, the
    closest ancestor is chosen.
    
    The return value is a dictionary. The format is recursive. These dicts have 
    the following entries:
     - 'cmd': list with the following structure: [cmd_name, arg1, arg2, ...]
       Will be [''] for the toplevel entry.
     - 'subcmds': list of dictionaries with an identical format to what we're
       describing here.
     - 'doc': documentation text.
     - 'origin': group command filename and line number.
    """
    
    # First, undo the command grouping as performed by parse_files. That
    # grouping is only used for documentation sections.
    commands = []
    for group in groups:
        
        # Add the group command to the list of commands.
        command = group.copy()
        command.pop('subcmds', None)
        commands += [command]
        
        # Add its subcommands to the list of commands.
        for subcmd in group['subcmds']:
            commands += [{
                'cmd': subcmd,
                'doc': '',
                'origin': command['origin']
            }]
    
    # Generate the root command.
    root = commands[0]
    root['subcmds'] = []
    
    # Use a stack structure of three-tuples to represent where we are in the
    # hierarchy. The first tuple entry is a reference to the current child
    # command list, the second entry lists the allowed child commands, the third
    # entry is a description of the parent node used in error messages.
    stack = [(
        root['subcmds'],
        copy.deepcopy(hierarchy[0][1]),
        'The document root'
    )]
    
    def pop_stack(stack):
        """Pops the topmost stack entry if child node requirements are met.
        
        If the stack was popped, None is returned. Otherwise, a string
        containing a user-friendly error message is returned."""
        patterns = stack[-1][1]
        parent_desc = stack[-1][2]
        
        # See if all child requirements have been met.
        for pattern in patterns:
            multip = pattern[-1]
            if multip == '+':
                return '%s requires at least one \\%s command.' % (parent_desc, pattern[:-1])
            elif multip == '!':
                return '%s requires exactly one \\%s command.' % (parent_desc, pattern[:-1])
        
        # Pop the stack.
        del stack[-1]
        return None
        
    
    # Loop over all commands in order. Ignore the first "command", which is just
    # a placeholder for ungrouped documentation. We will deal with that in the
    # end.
    for command in commands[1:]:
        cmd = command['cmd'][0]
        origin = command['origin']
        
        while len(stack) > 0:
            children = stack[-1][0]
            patterns = stack[-1][1]
            
            # Match the command name against the currently allowed commands.
            for i in range(len(patterns)):
                name = patterns[i][:-1]
                multip = patterns[i][-1]
                
                # Check if this pattern matches the command.
                if name != cmd:
                    continue
                
                # Pattern match, command fits here. Add the command to the child
                # list.
                children += [command]
                
                # Update the multiplicity if necessary.
                if multip in ['?', '!']:
                    del patterns[i]
                elif multip == '+':
                    patterns[i] = name + '*'
                
                # Find out if this command accepts child commands. If so, push
                # its child list and child patterns onto the stack.
                command['subcmds'] = []
                for h in hierarchy[1:]:
                    if cmd in h[0]:
                        stack += [(
                            command['subcmds'],
                            copy.deepcopy(h[1]),
                            '\\%s after line %s' % (cmd, origin)
                        )]
                        break
                
                # Break out of the pattern for loop.
                break
                
            else:
                # This command was not allowed as a child to the current parent.
                # See if we can pop from the stack (the child nodes of the
                # current parent adhere to the specification) to check if it's
                # allowed for the next ancestor.
                error = pop_stack(stack)
                if error is not None:
                    raise Exception('Misplaced \\%s after line %s, or %s' %
                                    (cmd, origin, error))
                continue
            
            # We only get here if we broke out of the pattern for loop after
            # adding the command, so we need to break the while loop as well to
            # go to the next command.
            break
            
        else:
            # We've depleted our options looking for a place to put this
            # command. That means the command simply wasn't allowed here.
            raise Exception('Misplaced \\%s after line %s.' % (cmd, origin))
    
    # Pop from the stack until it's empty, while checking whether the children
    # of all parent nodes on the stack adhere to the specifications.
    while len(stack) > 0:
        error = pop_stack(stack)
        if error is not None:
            raise Exception(error)
    
    return root

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
    
