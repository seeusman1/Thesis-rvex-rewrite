from __future__ import print_function

try:
    from configparser import ConfigParser
except ImportError:
    from ConfigParser import ConfigParser  # ver. < 3.0

from itertools import tee, izip

def pairwise(iterable):
    "s -> (s0,s1), (s1,s2), (s2, s3), ..."
    a, b = tee(iterable)
    next(b, None)
    return izip(a, b)


class CombiBlock:
    
    def __init__(self, stage, duration):
        self.stage = stage
        self.offset = 0
        self.duration = duration
        self.prv = []
        self.nxt = []
    
    def depends_on(self, depend):
        self.prv.append(depend)
        depend.nxt.append(self)
    
    def resolve():
        modified = False
        for p in self.prv:
            # If previous stage < our stage: there's a register in between.
            # If previous stage == our stage: combinatorial path.
            # If previous stage > our stage: combinatorial forwarding path.
            if p.stage >= self.stage:
                if p.offset + p.duration > self.offset:
                    self.offset = p.offset + p.duration
                    modified = True
        if modified:
            for n in self.nxt:
                n.resolve()


class LogicalBlock:
    
    def __init__(self, defs, name, durations):
        self.name = name
        if len(delays) == 1:
            self.blocks = [
                CombiBlock(defs['S_' + name], durations[0])]
        elif len(delays) == 2:
            self.blocks = [
                CombiBlock(defs['S_' + name], durations[0]),
                CombiBlock(defs['S_' + name] + defs['L_' + name], durations[1])]
        elif len(delays) == 3:
            self.blocks = [
                CombiBlock(defs['S_' + name], durations[0]),
                CombiBlock(defs['S_' + name] + defs['L_' + name + '1'], durations[1]),
                CombiBlock(defs['S_' + name] + defs['L_' + name], durations[2])]
        else:
            raise Exception()
        for bl1, bl2 in pairwise(self.blocks):
            bl2.depends_on(bl1)
    

def parse(indir):
    """Parses the pipeline configuration INI file.
    
    Returns a dictionary:
     - 'defs': dictionary from key to integer for all stage and latency
       definitions.
    """
    
    # Parse the ini file.
    config = ConfigParser()
    config.read(indir + '/pipeline.ini')
    
    # Check and load all the explicit things.
    defs = {}
    for name, preds in [
        ('S_FIRST', ['x == 1']),
        ('S_IF',    ['x >= 1']),
        ('L_IF',    ['x == 1']),
        ('S_PCP1',  ['x == 1 or x == 2']),
        ('S_BTGT',  ['x >= S_PCP1', 
                     'x >= S_IF + L_IF']),
        ('S_STOP',  ['x == S_IF + L_IF']),
        ('S_LIMM',  ['x >= S_STOP']),
        ('S_TRAP',  ['x >= 1']),
        ('S_RD',    ['x >= S_IF + L_IF']),
        ('L_RD',    ['x == 1']),
        ('S_SRD',   ['x >= S_IF + L_IF']),
        ('S_FW',    ['x >= S_RD + L_RD']),
        ('S_SFW',   ['x >= S_SRD']),
        ('S_BR',    ['x >= S_BTGT',
                     'x >= S_SRD',
                     'x >= S_PCP1',
                     'x > S_TRAP']),
        ('S_ALU',   ['x >= S_LIMM',
                     'x >= S_RD + L_RD',
                     'x >= S_SRD']),
        ('L_ALU1',  ['x == 0 or x == 1']),
        ('L_ALU2',  ['x == 0 or x == 1']),
        ('S_MUL',   ['x >= S_LIMM',
                     'x >= S_RD + L_RD',
                     'x >= S_SRD']),
        ('L_MUL1',  ['x >= 0']),
        ('L_MUL2',  ['x >= 0']),
        ('S_FADD',  ['x >= S_LIMM',
                     'x >= S_RD + L_RD',
                     'x >= S_SRD']),
        ('L_FADD1', ['x == 0 or x == 1']),
        ('L_FADD2', ['x == 0 or x == 1']),
        ('L_FADD3', ['x == 0 or x == 1']),
        ('S_FCMP',  ['x >= S_LIMM',
                     'x >= S_RD + L_RD',
                     'x >= S_SRD']),
        ('L_FCMP1', ['x == 0 or x == 1']),
        ('L_FCMP2', ['x == 0 or x == 1']),
        ('S_FCFI',  ['x >= S_LIMM',
                     'x >= S_RD + L_RD',
                     'x >= S_SRD']),
        ('S_FCIF',  ['x >= S_LIMM',
                     'x >= S_RD + L_RD',
                     'x >= S_SRD']),
        ('L_FCIF1', ['x == 0 or x == 1']),
        ('L_FCIF2', ['x == 0 or x == 1']),
        ('S_FMUL',  ['x >= S_LIMM',
                     'x >= S_RD + L_RD',
                     'x >= S_SRD']),
        ('L_FMUL1', ['x == 0 or x == 1']),
        ('L_FMUL2', ['x == 0 or x == 1']),
        ('L_FMUL3', ['x == 0 or x == 1']),
        ('S_MEM',   ['x >= S_RD + L_RD',
                     'x >= S_SRD',
                     'x >= S_ALU + L_ALU1']),
        ('L_MEM',   ['x >= 1']),
        ('S_BRK',   ['x >= S_ALU + L_ALU1']),
        ('L_BRK',   ['x == 0']),
        ('S_WB',    ['x >= S_ALU + L_ALU1 + L_ALU2',
                     'x >= S_MUL + L_MUL1 + L_MUL2',
                     'x >= S_FADD + L_FADD1 + L_FADD2 + L_FADD3',
                     'x >= S_FCMP + L_FCMP1 + L_FCMP2',
                     'x >= S_FCFI',
                     'x >= S_FCIF + L_FCIF1 + L_FCIF2',
                     'x >= S_FMUL + L_FMUL1 + L_FMUL2 + L_FMUL3',
                     'x >= S_MEM + L_MEM']),
        ('L_WB',    ['x == 1']),
        ('S_SWB',   ['x >= S_ALU + L_ALU1 + L_ALU2',
                     'x >= S_MUL + L_MUL1 + L_MUL2',
                     'x >= S_FADD + L_FADD1 + L_FADD2 + L_FADD3',
                     'x >= S_FCMP + L_FCMP1 + L_FCMP2',
                     'x >= S_FCFI',
                     'x >= S_FCIF + L_FCIF1 + L_FCIF2',
                     'x >= S_FMUL + L_FMUL1 + L_FMUL2 + L_FMUL3',
                     'x >= S_MEM + L_MEM']),
        ('S_LTRP',  ['x >= S_MEM + L_MEM']),
        ('S_LAST',  [])
    ]:
        defs[name] = defs['x'] = config.getint('pipeline', name)
        for pred in preds:
            if not eval(pred, {}, defs):
                raise Exception('Value for %s violates rule %s.' %
                                (name, pred.replace('x', name)))
        del defs['x']
    
    # Add some generated stuff.
    defs['L_ALU'] = defs['L_ALU1'] + defs['L_ALU2']
    defs['L_MUL'] = defs['L_MUL1'] + defs['L_MUL2']

    defs['L_FADD'] = defs['L_FADD1'] + defs['L_FADD2'] + defs['L_FADD3']
    defs['L_FCMP'] = defs['L_FCMP1'] + defs['L_FCMP2']
    defs['L_FCIF'] = defs['L_FCIF1'] + defs['L_FCIF2']
    defs['L_FMUL'] = defs['L_FMUL1'] + defs['L_FMUL2'] + defs['L_FMUL3']
    
    # This thing is a bit ugly. I don't know why this ever seemed like a good
    # idea. It has to do with the instruction buffer and the stop bit system and
    # it can only be 1.
    defs['L_IF_MEM'] = 1
    
    # TODO: check S_LAST.
    
    return {'defs': defs}







# Pipeline order:
#
# fetch       IF result
# ctrl        PCP1
# decode      STOP
# decode      (DEC (decode + illegal opcode check) = immediately after IF)
# ctrl        BTGT
# input       LIMM
# input       RD
# input       [FW result]
# input       SRD
# input       [SFW result]
# input       [OPMUX]
# ctrl        TRAP result
# ctrl        BR
# ctrl        (IF setup)
# arith       ALU
# arith       MUL
# arith       FPU
# ctrl/mem    MEM result
# ctrl        BRK
# ctrl        (STRAP)
# ctrl        [TRAP setup]
# ctrl        (RFI)
# mem         MEM setup
# output      WB
# output      [FW setup]
# output      SWB
# output      [SFW setup]
# debug       [DIAG]

# Dependencies: TODO
