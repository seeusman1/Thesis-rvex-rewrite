from __future__ import print_function

import common.templates
from code.back_end import *
from code.transform import *
from code.type_sys import *
from code.indentation import *

def generate(regs, dirs):
    for mo, mod, mode in [('gb', 'glob', 'global'), ('cx', 'ctxt', 'context')]:
        iface = regs[mo + 'iface']
        decl = regs[mo + 'decl']
        env = regs[mo + 'env']
        reglist = [x for x in regs['regmap'] if x is not None and mod in x]
        if mo == 'gb':
            bus_mux = busmux(reglist, regs['gbreg_size_log2'] - 2)
            bus_read = [bus_mux.format(
                addr = 'creg2gbreg_dbgAddr(%d downto 2)' % (regs['gbreg_size_log2'] - 1),
                data = 'gbreg2creg_dbgReadData',
            )]
            bus_read.append('for laneGroup in 0 to 2**CFG.numLaneGroupsLog2-1 loop\n')
            bus_read.append('\n'.join(['  ' + x for x in bus_mux.format(
                addr = 'creg2gbreg_coreAddr(laneGroup)(%d downto 2)' % (regs['gbreg_size_log2'] - 1),
                data = 'gbreg2creg_coreReadData(laneGroup)',
            ).split('\n')][:-1]) + '\n')
            bus_read.append('end loop;\n')
            bus_read = ''.join(bus_read)
        else:
            bus_read = busmux(reglist, regs['cxreg_size_log2'] - 2).format(
                addr = 'creg2cxreg_addr(ctxt)(%d downto 2)' % (regs['cxreg_size_log2'] - 1),
                data = 'cxreg2creg_readData(ctxt)',
            )
        
        common.templates.generate('vhdl',
            dirs['tmpldir'] + '/core_%sRegLogic.vhd' % mode,
            dirs['outdir'] + '/core_%sRegLogic.vhd' % mode,
            {
                'PORT_DECL':            ports(iface),
                'LIB_FUNCS':            generate_vhdl_libfuncs(),
                'REG_DECL':             decls(decl, env, True),
                'VAR_DECL':             decls(decl, env, False),
                'REG_RESET':            reset(iface, decl, env),
                'IMPL':                 impl(reglist),
                'RESET_IMPL':           impl(reglist, True),
                'BUS_READ':             bus_read,
                'OUTPUT_CONNECTIONS':   outconns(regs[mo + 'outconns'])
            })


def ports(iface):
    output = []
    for el in iface:
        if el[0] == 'group':
            output.append('-'*75 + '\n-- ' + el[1] + '\n' + '-'*75 + '\n')
        elif el[0] == 'doc':
            if el[1] != '':
                output.append(common.templates.rewrap(el[1], 75, '-- '))
        elif el[0] == 'space':
            output.append('\n')
        elif el[0] == 'ob':
            output.append(generate_declaration_vhdl(el[1]))
        else:
            raise Exception('Unknown element type %s.' % el[0])
    return ''.join(output)


def decls(obs, env, do_regs):
    output = []
    
    # Make sure that the constant initialization expressions only use predefined
    # constants and constants which have already been defined. They also cannot
    # use the ctxt loop iteration variable, because they are defined outside the
    # loop.
    defined_constants = set()
    def const_init_access(ob):
        if ob.name == 'ctxt':
            return False
        if isinstance(ob.atyp, PredefinedConstant):
            return True
        if isinstance(ob.atyp, Constant):
            return ob.name.lower() in defined_constants
        return False
    env = env.with_access_check(const_init_access)
    env.set_implicit_ctxt(None)
    
    # Loop over and generate all object declarations.
    for ob in obs:
        if (ob.atyp.name() == 'register') != do_regs:
            continue
        if ob.atyp.name() == 'constant':
            
            lenv = env.copy()
            lenv.set_user(ob.owner)
            
            # Parse the expression for constant object values.
            if ob.initspec is None:
                raise Exception('Constant object without init: \'%s\'.' % ob.name)
            init = transform_expression(
                ob.initspec, ob.origin, ob.atyp.typ, {}, lenv,
                'in constant \'%s\' initialization: ' % ob.name,
                True)[0]
            
            # Mark that this constant has been defined.
            defined_constants.add(ob.name.lower())
        
        else:
            init = None
        
        # Append the declaration.
        output.append(generate_declaration_vhdl(ob, init))
        
    return ''.join(output)


def reset(iface, decl, env):
    output = []
    
    # Make sure that the reset specifications only use constant and input
    # objects.
    def reset_access(ob):
        if isinstance(ob.atyp, PredefinedConstant):
            return True
        if isinstance(ob.atyp, Constant):
            return True
        if isinstance(ob.atyp, Input):
            return True
        return False
    env = env.with_access_check(reset_access)
    
    # Gather all register-like objects.
    obs = [x[1] for x in iface if x[0] == 'ob' and x[1].atyp.name() == 'output']
    obs += [x for x in decl if x.atyp.name() == 'register']
    
    # Loop over all and generate all of them.
    for ob in obs:
        if ob.initspec is None:
            raise Exception('Output or register object without reset: \'%s\'.' % ob.name)
        output.append(transform_assignment(
            ob, ob.initspec, ob.origin, {}, env,
            'in output/register \'%s\' reset: ' % ob.name)[0])
    
    return indentify(''.join(output), 'vhdl')


def impl(reglist, reset=False):
    vhdl = []
    for reg in reglist:
        vhdl.append(reg[('res' if reset else '') + 'impl_vhdl'])
    if not reset:
        for reg in reglist:
            vhdl.append(reg['finimpl_vhdl'])
    return ''.join(vhdl)


def busmux(reglist, addr_size, hi_fun=None):
    vhdl = []
    vhdl.append('case {addr} is\n')
    for reg in reglist:
        addr = str(bin(reg['offset'] // 4 + (1 << addr_size)))[-addr_size:] # yes, magic
        vhdl.append('  when "%s" => {data} <= %s;\n' % (addr, reg['read_vhdl']))
    vhdl.append('  when others => {data} <= (others => \'0\');\n')
    vhdl.append('end case;\n')
    return ''.join(vhdl)


def outconns(outconns):
    vhdl_glob = []
    vhdl_ctxt = []
    for key in outconns:
        outconn = outconns[key]
        if 'per_ctxt' in outconn:
            vhdl_ctxt.append(outconn['vhdl'])
        else:
            vhdl_glob.append(outconn['vhdl'])
    
    vhdl = []
    if len(vhdl_ctxt) > 0:
        vhdl.append('connect_gen: for ctxt in 0 to 2**CFG.numContextsLog2-1 generate\n')
        vhdl.append('\n'.join(['  %s' % x for x in ''.join(vhdl_ctxt).rstrip().split('\n')]) + '\n')
        vhdl.append('end generate;\n')
    vhdl.extend(vhdl_glob)
    return ''.join(vhdl)
