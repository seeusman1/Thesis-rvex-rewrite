from __future__ import print_function
import pprint

import common.templates

def generateReg(core_addr, core_prop, ctxt_addr, ctxt_prop, entry):
    name = entry[1]
    if not name.startswith('CR_'):
        return
    name = entry[1][3:]
    offset = entry[3]
    if entry[2][3] == 'W':
        size = 4
    elif entry[2][3] == 'H':
        size = 2
    elif entry[2][3] == 'B':
        size = 1
    else:
        raise Exception('Unknown size {} for register {}.'.format(entry[2][3],
            name))
    if entry[2][1] == 'W':
        writable = True
    elif entry[2][1] == 'R':
        writable = False
    else:
        raise Exception('Unknown permission {} for register {}.'.format(entry[2][1], name))
    if offset < 256:
        reg_type = 'GLOB'
        addr = core_addr
        prop = core_prop
    elif offset >= 512:
        reg_type = 'CTXT'
        offset = offset - 512
        addr = ctxt_addr
        prop = ctxt_prop
    else:
        raise Exception('Unknown register type at address 0x%03X.' % offset)
    addr.append('        self._{} = self._CREG_{} + 0x{:03X}\n'.format(name,
        reg_type, offset))
    getter = 'lambda s: s._rvd.readInt(s._{0}, {1})'
    if writable:
        setter = 'lambda s, v: s._rvd.writeInt(s._{0}, {1}, v)'
    else:
        setter = 'lambda s, v: raise_(RuntimeError("{0} is not writable"))'
    prop_str = ('    {0} = property(' + getter + ',\n' +
            '        ' + setter + ')\n').format(name, size)
    prop.append(prop_str)


def generateField(ent, core_prop, ctxt_prop):
    name = ent[1]
    if not name.startswith('CR_'):
        return
    regname = ent[5][0][3:]
    name = 'FIELD_' + name[3:]
    getter = "lambda self: (self.{1} & 0x{2:08X}) >> {3}"
    if ent[7] == 'R':
        setter = ("lambda self, val:raise_(" +
                "RuntimeError('Cannot write to field'))")
    else:
        setter = ("lambda s, val: setattr(s, '{1}', ((val << {3}) & 0x{2:08X}) |\n" +
                "            (self.{1} & ~0x{2:08X}))")
    string = ("    {0} = property(\n"+
            "        " + getter + ",\n" +
            "        " + setter + ")\n").format(
                    name, regname, ent[3], ent[2])
    if ent[6] < 256:
        core_prop.append(string)
    elif ent[6] >= 512:
        ctxt_prop.append(string)
    else:
        raise Exception('Unknown register type at address 0x{:03X}.'.format(
                ent[6]))


def generate(regs, trps, dirs):

    memmap = []
    core_addr = []
    core_prop = []
    ctxt_addr = []
    ctxt_prop = []
    for ent in regs['defs']:
        if ent[0] == 'reg':
            generateReg(core_addr, core_prop, ctxt_addr, ctxt_prop, ent)
        elif ent[0] == 'field':
            generateField(ent, core_prop, ctxt_prop)

    # Generate the file.
    common.templates.generate('memmap',
        dirs['tmpldir'] + '/core_map.py',
        dirs['outdir'] + '/core_map.py',
        {'CORE_REGISTER_ADDR': ''.join(core_addr),
            'CORE_REGISTER_PROP': ''.join(core_prop),
            'CTXT_REGISTER_ADDR': ''.join(ctxt_addr),
            'CTXT_REGISTER_PROP': ''.join(ctxt_prop)})
