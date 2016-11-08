#!/usr/bin/python3

import time
import random
import sys
from optparse import OptionParser, OptionGroup

o = OptionParser(usage='Usage: %prog [options]',
    description='Generates a conformance test file that thoroughly tests the '
    'correctness of the register file and forwarding logic. It strives to '
    'write/read/verify a 0 and a 1 for each bit of the register file, as well'
    'as each forwarding path, by randomly selecting instructions to get the'
    'highest increase in coverage.')

g = OptionGroup(o, 'Output options')
g.add_option('-o', type='string', dest='output_file',
    help='output to the specified file instead of stdout.')
g.add_option('-v', '--verbose', action='store_false', dest='quiet', default=True,
    help='print status information to stdout.')
o.add_option_group(g)

g = OptionGroup(o, 'Core configuration')
g.add_option('-l', '--lanes', type='int', dest='lanes', default=8,
    help='number of lanes to generate for.')
g.add_option('--S_RD', type='int', dest='S_RD', default=2,
    help='pipeline stage in which the read address is set up.')
g.add_option('--L_RD', type='int', dest='L_RD', default=1,
    help='number of pipeline stages needed to read from the regfile.')
g.add_option('--S_WB', type='int', dest='S_WB', default=5,
    help='pipeline stage in which the write address/data is set up.')
g.add_option('--L_WB', type='int', dest='L_WB', default=1,
    help='number of pipeline stages needed to write to the regfile.')
o.add_option_group(g)

g = OptionGroup(o, 'Generator options')
g.add_option('-b', '--blocklen', type='int', dest='block_len', default=256,
    help='number of bundles between register file dumps.')
g.add_option('-c', '--blockcount', type='int', dest='block_count', default=4,
    help='number of register file dumps.')
g.add_option('-s', '--seed', type='int', dest='seed',
    help='seed for the random generator, to get reproducible results.')
g.add_option('-e', '--effort', type='int', dest='effort', default=30,
    help='effort level.')
o.add_option_group(g)

opts, _ = o.parse_args()
globals().update(opts.__dict__)

#output_file = 'gpregs.test'
#quiet = True

## Number of lanes to generate for.
#lanes = 8

## Length of a block of code (number of bundles).
#block_len = 256

## Number of blocks. At the end of each block, all general purpose registers are
## dumped to memory.
#block_count = 4

## Random generator effort level (higher = slightly better results at the cost
## of script execution time) and seed.
#effort = 30
#seed = 0

## Pipeline configuration.
#S_RD = 2
#L_RD = 1
#S_WB = 5
#L_WB = 1


class AccessPortCoverage(object):
    """Remembers coverage information for a register file port."""
    
    def __init__(self, numregs, numbits):
        self.numbits = numbits
        self.maxval = (1 << numbits) - 1
        self.c = [0] * numregs
    
    def cover(self, addr, value):
        if value is None:
            return
        
        # Determine one's complement of the value.
        value &= self.maxval
        comp = self.maxval - value
        
        # Remember which bits were accessed as zeroes.
        self.c[addr] |= comp
        
        # Remember which bits were accessed as ones.
        self.c[addr] |= value << self.numbits
    
    def fitness(self, addr, value):
        """Returns how many bits were accessed with a value that hasn't
        been seen before."""
        if value is None:
            return 0
        
        value &= self.maxval
        comp = self.maxval - value
        new = cur = self.c[addr]
        new |= comp
        new |= value << self.numbits
        dif = new - cur
        return bin(dif).count('1')

    def get(self, cover, *args, **kwargs):
        if cover:
            self.cover(*args, **kwargs)
            return 0
        return self.fitness(*args, **kwargs)

    def percent(self):
        acc = cnt = 0
        for c in self.c[1:]:
            acc += bin(c).count('1') / 64
            cnt += 1
        return (acc / cnt) * 100.0


class ForwardPathCoverage(object):
    """Remembers coverage information for a forwarding path."""
    
    def __init__(self, numrd, numwr, firststage, numstage):
        self.numrd = numrd
        self.numwr = numwr
        self.numstage = numstage
        self.firststage = firststage
        self.covered = [True] * (
            self.numrd
            * self.numwr * (self.numstage+1)
            * ((self.numwr * (self.numstage+1)) + 1)
        )
        
        p = []
        for rdport in range(self.numrd):
            for age in range(min(3, self.numwr)):
                # Data from register file.
                p.append(self.get_idx(rdport, age))
            for wrport1 in range(self.numwr):
                for stage1 in range(self.numstage):
                    for age in range(min(3, self.numwr)):
                        # Forwarding path overriding register file.
                        p.append(self.get_idx(rdport, wrport1, stage1, age))
                    for wrport2 in range(self.numwr):
                        for stage2 in range(stage1+1, self.numstage):
                            # Forwarding path overriding another forwarding path.
                            p.append(self.get_idx(rdport, wrport1, stage1, wrport2, stage2))
        for i in p:
            self.covered[i] = False
        self.relevant_paths = p
    
    def get_idx(self, rdport, wrport1, stage1=None, wrport2=None, stage2=None):
        # (rdport) received value from (wrport1, stage1), [overruling (wrport2, stage2)]
        # rdport in range(numrd)
        # wrport in range(numwr)
        # stage in range(numstage) or None for register file
        
        stage1 = self.numstage if stage1 is None else stage1 - self.firststage
        stage2 = self.numstage if stage2 is None else stage2 - self.firststage
        
        idx = 0
        
        # Consider the access port.
        idx *= self.numrd
        idx += rdport
        
        # Consider the actual source.
        idx *= self.numwr
        idx += wrport1
        
        # Consider the stage of the actual source.
        idx *= self.numstage+1
        idx += stage1
        
        idx *= (self.numwr * (self.numstage+1)) + 1
        
        if wrport2 is not None:
            
            sidx = 0
            
            # Consider the overruled write port.
            sidx *= self.numwr
            sidx += 1 + wrport2
            
            # Consider the overruled stage.
            sidx *= self.numstage+1
            sidx += stage2
        
            # Reserve index zero for no overrulings.
            idx += sidx + 1
        
        return idx
    
    def cover(self, *args, **kwargs):
        idx = self.get_idx(*args, **kwargs)
        if idx >= len(self.covered):
            self.covered += [False] * (idx+1 - len(self.covered))
        self.covered[idx] = True
    
    def fitness(self, *args, **kwargs):
        """Returns 1 when the given access pattern is not covered yet."""
        idx = self.get_idx(*args, **kwargs)
        if idx >= len(self.covered):
            return 1
        if not self.covered[idx]:
            return 1
        return 0
    
    def get(self, cover, *args, **kwargs):
        if cover:
            self.cover(*args, **kwargs)
            return 0
        return self.fitness(*args, **kwargs)
    
    def percent(self):
        cnt = acc = 0
        for path in self.relevant_paths:
            cnt += 1
            if self.covered[path]:
                acc += 1
        return (acc / cnt) * 100.0


class RvexGpReg(object):
    """This class emulates the general purpose register file and forwarding
    logic. It can also handle coverage.
    
    For emulation, the following model is used:
     - read() the register file for all lanes.
     - Process the instructions.
     - write() the results of the instructions.
     - If necessary, cancel() pending writes due to a trap.
     - Call cycle() to advance to the next clock cycle.
    """
    
    class PendingWrite(object):
        def __init__(self, cur_stage, avail_stage, lane, addr, value):
            self.cur_stage = cur_stage
            self.avail_stage = avail_stage
            self.lane = lane
            self.addr = addr
            self.value = value
        
        def cycle(self):
            self.cur_stage += 1
            return self.cur_stage
        
        def check(self, addr):
            if addr != self.addr:
                return False
            if self.cur_stage < self.avail_stage:
                return False
            return True
        
        def __lt__(self, other):
            return self.cur_stage < other.cur_stage
    
    def __init__(self, S_RD, L_RD, S_WB, L_WB, numlanes):
        """Creates a new register file containing only undefined data."""
        self.S_READ = S_RD + L_RD
        self.S_WRITE = S_WB + L_WB
        self.numlanes = numlanes
        self.regs = [None] * 64
        self.age = [0] * 64
        self.pending = []
        self.regrdcov = [AccessPortCoverage(64, 32) for i in range(numlanes*2)]
        self.regwrcov = [AccessPortCoverage(64, 32) for i in range(numlanes)]
        self.fwdvalcov = [[AccessPortCoverage(64, 32) for i in range(numlanes)] for i in range(numlanes*2)]
        self.fwdpathcov = ForwardPathCoverage(numlanes*2, numlanes, self.S_READ+1, self.S_WRITE - self.S_READ - 1)
    
    # Emulation functions.
    def read(self, lane, port, addr, cover=True):
        """Processes a read from register <addr>, originating from access port
        <port> (0 for op1 or 1 for op2) of <lane>. If cover is False, coverage
        information is not updated. Returns a three-tuple consisting of the read
        value or None if undefined, the fitness of this read for increasing
        coverage if cover is False, and whether the value was forwarded or not.
        """
        
        # Handle register $r0.0.
        if addr == 0:
            return 0, 0, False
        
        # Handle forwarding.
        forwarded = None
        overruled = None
        for p in self.pending:
            if not p.check(addr):
                continue
                
            # Found a pending write eligible for forwarding.
            if forwarded is not None:
                if p.cur_stage > forwarded.cur_stage:
                    # The pending write that we found before overrules this one.
                    overruled = p
                    break
            if forwarded is None:
                # Forwarded value.
                forwarded = p
            else:
                # Multiple simultaneous writes to the same register.
                return None, 0, True
        
        # Determine the value.
        value = self.regs[addr] if forwarded is None else forwarded.value
        
        # Determine fitness/update coverage.
        rdport = lane*2 + port
        if forwarded is None:
            wrport1 = min(self.age[addr], 2) # Abuse port as age.
            stage1 = None # Source = register file.
            wrport2 = None
            stage2 = None
        else:
            wrport1 = forwarded.lane
            stage1 = forwarded.cur_stage
            if overruled is None:
                wrport2 = min(self.age[addr], 2) # Abuse port as age.
                stage2 = None # Overruled = register file.
            else:
                wrport2 = overruled.lane
                stage2 = overruled.cur_stage
        
        fitness = 32 * self.fwdpathcov.get(cover, rdport, wrport1, stage1, wrport2, stage2)
        
        if forwarded is None:
            fitness += self.regrdcov[rdport].get(cover, addr, value)
        else:
            fitness += self.fwdvalcov[rdport][wrport1].get(cover, addr, value)
        
        return value, fitness, forwarded is not None
    
    def write(self, cur_stage, avail_stage, lane, addr, value, cover=True, execute=None):
        """Pends a write to register <addr> with value <value>, originating
        from lane <lane> stage <cur_stage>, and becoming available in
        <avail_stage>."""
        if execute is None:
            execute = cover
        if execute:
            self.pending.append(self.PendingWrite(cur_stage, avail_stage, lane, addr, value))
        return self.regwrcov[lane].get(cover, addr, value)
    
    def cancel(self, stage):
        """Cancels any pending writes due to a trap in the given stage."""
        new_pending = []
        for p in self.pending:
            if p.cur_stage > stage:
                new_pending.append(p)
        self.pending = new_pending
    
    def cycle(self):
        """Processes a clock cycle."""
        new_pending = []
        written_data = {}
        for p in self.pending:
            if p.cycle() == self.S_WRITE:
                if p.addr in written_data:
                    # Multiple simultaneous writes.
                    written_data[p.addr] = None
                else:
                    written_data[p.addr] = p.value
            else:
                new_pending.append(p)
        self.pending = sorted(new_pending)
        
        for i in range(len(self.age)):
            self.age[i] += 1
        for addr in written_data:
            self.regs[addr] = written_data[addr]
            self.age[addr] = 0
    
    def print_state(self):
        data = [{} for i in range(self.S_WRITE - (self.S_READ+1))]
        for p in self.pending:
            if p.cur_stage < p.avail_stage:
                continue
            d = data[p.cur_stage - (self.S_READ+1)]
            if p.addr not in d:
                d[p.addr] = p.value
            else:
                d[p.addr] = None
        
        s  = '| Reg.   | '
        sp = '|--------+-'
        for stage in range(self.S_READ+1, self.S_WRITE):
            s  += 'Fwd stg. %d | ' % stage
            sp += '-----------+-'
        s  += 'Current    | Age   |'
        sp += '-----------+-------|'
        
        s = s + ' ' + s
        sp = sp + ' ' + sp
        
        print(sp.replace('+', '.').replace('|', '.'))
        print(s)
        
        for a1 in range(0, 32):
            if a1 % 16 == 0:
                print(sp)
            s = ''
            for addr in [a1, a1+32]:
                s += '| $r0.%-2d | ' % addr
                for d in data:
                    if addr not in d:
                        s += '           | '
                    elif d[addr] is None:
                        s += '0xUUUUUUUU | '
                    else:
                        s += '0x%08X | ' % d[addr]
                if self.regs[addr] is None:
                    s += '0xUUUUUUUU | '
                else:
                    s += '0x%08X | ' % self.regs[addr]
                s += '%-5d |' % self.age[addr]
                s += ' '
            print(s.strip())
        print(sp.replace('+', '\'').replace('|', '\''))

    def print_coverage(self):
        
        acc = cnt = 0
        for i in self.regrdcov:
            acc += i.percent()
            cnt += 1
        print('Read bit coverage: %f%%' % (acc / cnt))
        
        acc = cnt = 0
        for i in self.regwrcov:
            acc += i.percent()
            cnt += 1
        print('Write bit coverage: %f%%' % (acc / cnt))
        
        acc = cnt = 0
        for i in self.fwdvalcov:
            for j in i:
                acc += j.percent()
                cnt += 1
        print('Forward bit coverage: %f%%' % (acc / cnt))
        
        #print('Forward path coverage: %f%%' % self.fwdpathcov.percent())


class Syllable(object):
    def __init__(self, lane):
        self.lane = lane
    
    def run(self, gp, cover=True, execute=True):
        return
    
    def disas(self, f):
        print('\t#nop', file=f)
    
    def get_dests(self):
        return []
    
    def get_srcs(self):
        return []
    
    def get_saved(self):
        return []

    def test(self, f, stop):
        print('load    nop' + stop, file=f)

class XorSyllable(Syllable):
    def __init__(self, lane, dest, src1, src2, imm=None):
        self.lane = lane
        self.dest = dest
        self.src1 = src1
        self.src2 = src2
        self.imm = imm
    
    def run(self, gp, cover=True, execute=True):
        op1, fitness, _ = gp.read(self.lane, 0, self.src1, cover)
        if self.imm is None:
            op2, fit, _ = gp.read(self.lane, 1, self.src2, cover)
            fitness += fit
        else:
            op2 = self.imm
        if op1 is not None and op2 is not None:
            res = op1 ^ op2
        else:
            res = None
        gp.write(3, 4, self.lane, self.dest, res, cover, execute)
        return fitness, res
        
    def disas(self, f):
        if self.imm is None:
            print('\txor $r0.%-2d = $r0.%-2d, $r0.%-2d' % 
                    (self.dest, self.src1, self.src2), file=f)
        else:
            print('\txor $r0.%-2d = $r0.%-2d, 0x%08X' % 
                (self.dest, self.src1, self.imm), file=f)
    
    def test(self, f, stop):
        if self.imm is None:
            print('load    xor r0.%-2d = r0.%-2d, r0.%-2d%s' % 
                    (self.dest, self.src1, self.src2, stop), file=f)
        else:
            print('load    xor r0.%-2d = r0.%-2d, 0x%08x%s' % 
                (self.dest, self.src1, self.imm, stop), file=f)
    
    def get_dests(self):
        return [self.dest]
    
    def get_srcs(self):
        if self.imm is None:
            return [self.src1, self.src2]
        else:
            return [self.src1]


class LimmhSyllable(Syllable):
    def __init__(self, lane, tgt):
        self.lane = lane
        self.tgt = tgt
    
    def disas(self, f):
        if self.lane < self.tgt.lane:
            print('\t#limmh --v', file=f)
        else:
            print('\t#limmh --^', file=f)

    def test(self, f, stop):
        print('load    limmh %d, 0x%08x%s' % (self.tgt.lane, self.tgt.imm, stop), file=f)


class CallSyllable(Syllable):
    def __init__(self, lane, label, srcs=[1, 3], dests=[1, 3], saved=[]):
        self.lane = lane
        self.label = label
        self.srcs = srcs
        self.dests = dests
        self.saved = saved
    
    def run(self, gp, cover=True, execute=True):
        if execute:
            for i in range(10):
                gp.cycle()
    
    def disas(self, f):
        print('\tcall %s' % self.label, file=f)

    def test(self, f, stop):
        raise NotImplemented()

    def get_srcs(self):
        return list(self.srcs)

    def get_dests(self):
        return list(self.dests)

    def get_saved(self):
        return list(self.saved)

class Bundle(object):
    
    def execute(self, gp=None, cover=True):
        if gp is None:
            gp = self.gp
        for syl in self.bundle:
            syl.run(gp, cover, True)
    
    def disas(self, f=None):
        if f is None:
            f = sys.stdout
        for syl in self.bundle:
            syl.disas(f)
        print(';;', file=f)
    
    def test(self, f=None):
        if f is None:
            f = sys.stdout
        for syl in self.bundle[:-1]:
            syl.test(f, '')
        self.bundle[-1].test(f, ' ;;')
        print(file=f)
    
    def __iter__(self):
        return iter(self.bundle)
    
    def __getitem__(self, idx):
        return self.bundle[idx]
    
    def __len__(self):
        return len(self.bundle)


class DumpBundle(Bundle):
    def __init__(self, gp):
        self.gp = gp
        self.numlanes = gp.numlanes
        self.bundle = [Syllable(i) for i in range(gp.numlanes-1)]
        self.bundle.append(CallSyllable(gp.numlanes-1, 'dump_regs', [], [], range(1, 64)))
    
    def test(self, f=None):
        if f is None:
            f = sys.stdout
        for i in range(1, 64):
            for j in range(self.numlanes-2):
                print('load    nop', file=f)
            print('load    stw %d[r0.0] = r0.%d' % (i*4, i), file=f)
            print('load    nop ;;', file=f)
            print('', file=f)

class RandomBundle(Bundle):
    
    def get_random_xor(self, lane, valid_dests, valid_srcs, use_limm):
        dest = random.choice(valid_dests)
        src1 = random.choice(valid_srcs)
        if use_limm:
            return XorSyllable(lane, dest, src1, None, random.randint(0, 0xFFFFFFFF))
        else:
            return XorSyllable(lane, dest, src1, random.choice(valid_srcs))
    
    def get_random_xors(self, lane, valid_dests, valid_srcs):
        val_dests = list(valid_dests)
        fits = 0
        xors = []
        for l in [lane, lane+1]:
            best_fit = -10
            best_xor = None
            x = 0
            while x < effort:
                x += 1
                xor = self.get_random_xor(l, val_dests, valid_srcs, False)
                fit, res = xor.run(self.gp, False, False)
                if res == 0:
                    continue
                if best_xor is None or fit > best_fit:
                    best_fit = fit
                    best_xor = xor
                    x = 0
            if best_xor is None:
                continue
            fits += best_fit
            xors.append(best_xor)
            val_dests.remove(best_xor.dest)
        
        for x in range(effort):
            xor = self.get_random_xor(lane, valid_dests, valid_srcs, True)
            fit, res = xor.run(self.gp, False, False)
            if fit >= fits:
                fits = fit
                xors = [xor, LimmhSyllable(lane + 1, xor)]
        
        return xors, fits
    
    def get_random_bundle(self):
        valid_dests = list(range(1, 64))
        valid_srcs = [0] + [x for x in range(1, 64) if self.gp.regs[x] is not None]
        syllables = [None] * self.numlanes
        fitness = 0
        for lane in range(0, self.numlanes, 2):
            xors, fits = self.get_random_xors(lane, valid_dests, valid_srcs)
            for xor in xors:
                syllables[xor.lane] = xor
                try:
                    valid_dests.remove(xor.dest)
                except AttributeError:
                    pass
            fitness += fits
        
        return syllables, fitness
    
    def __init__(self, gp):
        self.gp = gp
        self.numlanes = gp.numlanes
        self.bundle, self.fitness = self.get_random_bundle()
        for i in range(self.numlanes):
            if self.bundle[i] is None:
                self.bundle[i] = NopSyllable(i)



if seed is not None:
    random.seed(seed)

regs = RvexGpReg(S_RD, L_RD, S_WB, L_WB, lanes)

bundles = []
checkpoints = []
for i in range(block_len * block_count):
    if i % block_len == block_len-1:
        b = DumpBundle(regs)
    else:
        b = RandomBundle(regs)
    bundles.append(b)
    b.execute()
    regs.cycle()
    
    if i % 4 == 0:
        if not quiet:
            print(end='.')
            sys.stdout.flush()

    if i % block_len == block_len-1:
        covered = [None for b in bundles] + [[True]*64]
        for i, b in reversed(list(enumerate(bundles))):
            covered[i] = list(covered[i+1])
            for syl in b:
                for dest in syl.get_dests():
                    covered[i][dest] = False
            for syl in b:
                for dest in syl.get_dests():
                    if covered[i+1][dest]:
                        for src in syl.get_srcs():
                            covered[i][src] = True
                        break
                for src in syl.get_saved():
                    covered[i][src] = True
        
        checkpoints.append(regs)
        
        regs = RvexGpReg(S_RD, L_RD, S_WB, L_WB, lanes)
        for i, b in enumerate(bundles):
            for lane, syl in enumerate(b):
                c = False
                for dest in syl.get_dests():
                    if covered[i+1][dest]:
                        c = True
                        break
                syl.run(regs, c, True)
            regs.cycle()
        
        if not quiet:
            print()
            regs.print_coverage()


def print_test_file(f):
    print('name    Thoroughly test %d-way gpreg and forwarding' % lanes, file=f)
    print('', file=f)
    print('config  numLanes              %d' % lanes, file=f)
    print('config  memLaneRevIndex       1', file=f)
    print('config  branchLaneRevIndex    0', file=f)
    print('config  forwarding            1', file=f)
    print('', file=f)
    print('init', file=f)
    print('', file=f)
    for b in bundles:
        b.test(f)
    for i in range(lanes-1):
        print('load    nop', file=f)
    print('load    stop ;;', file=f)
    print('', file=f)
    print('reset', file=f)
    print('', file=f)
    for c in checkpoints:
        for reg in range(1, 64):
            wait = block_len * 10 if reg == 1 else 40
            print('wait    %-4d write *  %-3d 0x%08X exclusive' % (wait, reg*4, c.regs[reg]), file=f)
    print('wait    40 idle 0', file=f)
    print('', file=f)

if output_file is None:
    print_test_file(sys.stdout)
else:
    with open(output_file, 'w') as f:
        print_test_file(f)
