from __future__ import print_function

import common.templates
from code.back_end import *
from code.transform import *
from code.type_sys import *
from code.indentation import *
import itertools

CREGS_SIM_FUNC_TEMPLATE = r"""
/**
 * Simulates the control register logic. This function is generated.
 */
#pragma GCC diagnostic ignored "-Woverflow"
#pragma GCC diagnostic ignored "-Wunused-variable"
#pragma GCC diagnostic ignored "-Wmaybe-uninitialized"
#pragma GCC diagnostic ignored "-Wpedantic"
void Core::simulateControlRegLogic() {

    // Make CFG available to the code, as it is in VHDL.
    const cfgVect_t &CFG = generics.CFG;

    // Make a copy of the current state, so registers behave the way they should.
    // Hopefully gcc will optimize the shit out of this.
    globalRegState_t oldGbregState = st.gbregState;
    contextRegState_t oldCxregState[CORE_MAX_CONTEXTS];
    for (int ctxt = 0; ctxt < (1 << CFG.numContextsLog2); ctxt++) {
        oldCxregState[ctxt] = st.cx[ctxt].cxregState;
    }

    if (st.reset) {

        // Reset code.
        st.cregIface.gbreg_dbgReadData = 0;
        @GLOBAL_RESET
        for (int lg = 0; lg < (1 << CFG.numLaneGroupsLog2); lg++) {
            st.cregIface.gbreg_coreReadData[lg] = 0;
        }
        for (int ctxt = 0; ctxt < (1 << CFG.numContextsLog2); ctxt++) {
            st.cx[ctxt].cregIface.cxreg_readData = 0;
            @CONTEXT_RESET
        }

    } else if (st.clkEn) {

        // Global control register file.
        if (1) {

            // Language-agnostic code declarations.
            @GLOBAL_DECL

            // Bus decoding.
            data_t bus_writeData = st.cregIface.gbreg_dbgWriteData;
            data_t bus_writeMaskDbg = 0;
            if (st.cregIface.gbreg_dbgWriteMask & 1) bus_writeMaskDbg |= 0x000000FF;
            if (st.cregIface.gbreg_dbgWriteMask & 2) bus_writeMaskDbg |= 0x0000FF00;
            if (st.cregIface.gbreg_dbgWriteMask & 4) bus_writeMaskDbg |= 0x00FF0000;
            if (st.cregIface.gbreg_dbgWriteMask & 8) bus_writeMaskDbg |= 0xFF000000;
            unsigned6_t bus_wordAddr = st.cregIface.gbreg_dbgAddress >> 2;
            if (st.cregIface.gbreg_dbgAddress < 0) {
                bus_wordAddr = 0;
                bus_writeMaskDbg = 0;
            }

            // Language-agnostic code.
            bit_t perf_count_clear = 0;
            @GLOBAL_IMPL

            // Bus read demuxing.
            for (int _lg = -1; _lg < (1 << CFG.numLaneGroupsLog2); _lg++) {
                uint16_t addr;
                uint32_t *data;
                if (_lg == -1) {
                    addr = st.cregIface.gbreg_dbgAddress;
                    data = &(st.cregIface.gbreg_dbgReadData);
                } else {
                    addr = st.cregIface.gbreg_coreAddress[_lg];
                    data = &(st.cregIface.gbreg_coreReadData[_lg]);
                }
                if (addr < 0) {
                    *data = 0xDEADC0DE;
                    continue;
                } else {
                    *data = 0;
                }
                switch ((addr >> 2) & 0x3F) {
                @GLOBAL_BUSREAD
                }
            }
        }

        // Context control register file.
        for (int ctxt = 0; ctxt < (1 << CFG.numContextsLog2); ctxt++) {

            // Language-agnostic code declarations.
            @CONTEXT_DECL

            // Context soft reset.
            if (st.cx[ctxt].cregIface.cxreg_reset) {
                st.cx[ctxt].cregIface.cxreg_readData = 0;
                @CONTEXT_RESET
                @CONTEXT_RESETIMPL
                continue;
            }

            // Bus decoding.
            data_t bus_writeData = st.cx[ctxt].cregIface.cxreg_writeData;
            data_t _mask = 0;
            if (st.cx[ctxt].cregIface.cxreg_writeMask & 1) _mask |= 0x000000FF;
            if (st.cx[ctxt].cregIface.cxreg_writeMask & 2) _mask |= 0x0000FF00;
            if (st.cx[ctxt].cregIface.cxreg_writeMask & 4) _mask |= 0x00FF0000;
            if (st.cx[ctxt].cregIface.cxreg_writeMask & 8) _mask |= 0xFF000000;
            unsigned7_t bus_wordAddr = st.cx[ctxt].cregIface.cxreg_address >> 2;
            if (st.cx[ctxt].cregIface.cxreg_address < 0) {
                bus_wordAddr = 0;
                _mask = 0;
            }
            data_t bus_writeMaskDbg = st.cx[ctxt].cregIface.cxreg_origin ? _mask : 0;
            data_t bus_writeMaskCore = st.cx[ctxt].cregIface.cxreg_origin ? 0 : _mask;

            // Language-agnostic code.
            bit_t perf_count_clear = 0;
            @CONTEXT_IMPL

            // Bus read demuxing.
            if (st.cx[ctxt].cregIface.cxreg_address < 0) {
                st.cx[ctxt].cregIface.cxreg_readData = 0xDEADC0DE;
                continue;
            } else {
                st.cx[ctxt].cregIface.cxreg_readData = 0;
            }
            switch (bus_wordAddr & 0x7F) {
            @CONTEXT_BUSREAD
            }
        }

    } else {
        return;
    }

    // Tie states immediately to outputs.
    @GLOBAL_OUTCONN
    for (int ctxt = 0; ctxt < (1 << CFG.numContextsLog2); ctxt++) {
        @CONTEXT_OUTCONN
    }

}
"""

def generate(regs, header, source):
    """Generates the implementation code for the control registers."""
    
    # Input/output.
    for mo, mod, mode in [('gb', 'glob', 'global'), ('cx', 'ctxt', 'context')]:
        name = 'CtrlRegInterface%s_t' % ('PerCtxt' if mo == 'cx' else '')
        output = []
        output.append('typedef struct %s {\n' % name)
        if mo == 'cx':
            output.append('\n')
            output.append('    // System control.\n')
            output.append('    uint8_t      cxreg_reset;\n')
        
        for ty, el in itertools.chain(
            itertools.imap(lambda x: ('Global cregs', x), regs['gbiface']),
            itertools.imap(lambda x: ('Context cregs', x), regs['cxiface'])):
            if el[0] == 'group':
                output.append('\n    // %s: %s.\n' % (ty, el[1]))
            elif el[0] == 'ob':
                if el[1].atyp.typ.exists_per_context() == (mo == 'cx'):
                    output.append('    ' + generate_declaration_c(el[1]))
        
        output.append('\n')
        if mo == 'cx':
            output.append('    // Core/debug bus interface. Address is set to -1 to disable access.\n')
            output.append('    // Origin is set to 0 for a core access or to 1 for a debug access.\n')
            output.append('    int16_t      cxreg_address;\n')
            output.append('    uint8_t      cxreg_origin;\n')
            output.append('    uint8_t      cxreg_writeMask;\n')
            output.append('    uint32_t     cxreg_readData;\n')
            output.append('    uint32_t     cxreg_writeData;\n')
        else:
            output.append('    // Debug bus interface. Address is set to -1 to disable access.\n')
            output.append('    int16_t      gbreg_dbgAddress;\n')
            output.append('    uint8_t      gbreg_dbgWriteMask;\n')
            output.append('    uint32_t     gbreg_dbgReadData;\n')
            output.append('    uint32_t     gbreg_dbgWriteData;\n')
            output.append('\n')
            output.append('    // Core interfaces. Address is set to -1 to disable access.\n')
            output.append('    int16_t      gbreg_coreAddress[CORE_MAX_LANE_GROUPS];\n')
            output.append('    uint32_t     gbreg_coreReadData[CORE_MAX_LANE_GROUPS];\n')
        output.append('\n')
        output.append('} %s;\n\n' % name)
        header.append(''.join(output))
    
    # Registers.
    for mo, mod, mode in [('gb', 'glob', 'global'), ('cx', 'ctxt', 'context')]:
        output = []
        output.append('typedef struct %sRegState_t {\n' % mode)
        for ob in regs[mo + 'decl']:
            if ob.atyp.name() != 'register':
                continue
            output.append('    ' + generate_declaration_c(ob))
        output.append('} %sRegState_t;\n\n' % mode)
        header.append(''.join(output))
    
    # Actual code.
    data = {}
    outconn_dict = regs['gboutconns'].copy()
    outconn_dict.update(regs['cxoutconns'])
    for mo, mod, mode in [('gb', 'glob', 'global'), ('cx', 'ctxt', 'context')]:
        iface = regs[mo + 'iface']
        decl = regs[mo + 'decl']
        env = regs[mo + 'env']
        reglist = [x for x in regs['regmap'] if x is not None and mod in x]
        dnam = 'st.cx[ctxt].cregIface.cxreg_readData' if mo == 'cx' else '*data'
        amask = 0x7F if mo == 'cx' else 0x3F
        busmux = ''.join([
            'case %d: %s = %s; break;\n' % (
                (reg['offset'] // 4) & amask,
                dnam, reg['read_c']
            ) for reg in reglist])
        
        data['%s_DECL' % mode.upper()]      = decls(decl, env)
        data['%s_RESET' % mode.upper()]     = reset(iface, decl, env)
        data['%s_IMPL' % mode.upper()]      = impl(reglist)
        data['%s_RESETIMPL' % mode.upper()] = impl(reglist, True)
        data['%s_BUSREAD' % mode.upper()]   = busmux
        data['%s_OUTCONN' % mode.upper()]   = outconns(outconn_dict, mo == 'cx')
    
    source.append(common.templates.process_template(CREGS_SIM_FUNC_TEMPLATE, data))
    

def decls(obs, env):
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
        if ob.atyp.name() == 'register':
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
                True)[1]
            
            # Mark that this constant has been defined.
            defined_constants.add(ob.name.lower())
        
        else:
            init = None
        
        # Append the declaration.
        output.append(generate_declaration_c(ob, init))
        
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
            'in output/register \'%s\' reset: ' % ob.name)[1])
    
    return indentify(''.join(output), 'c')


def impl(reglist, reset=False):
    c = []
    for reg in reglist:
        c.append(reg[('res' if reset else '') + 'impl_c'])
    if not reset:
        for reg in reglist:
            c.append(reg['finimpl_c'])
    return ''.join(c)


def outconns(outconns, per_ctxt):
    output = []
    for key in outconns:
        outconn = outconns[key]
        if ('per_ctxt' in outconn) == per_ctxt:
            output.append(outconn['c'])
    return ''.join(output)


