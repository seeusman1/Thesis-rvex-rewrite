from collections import OrderedDict

def raise_(ex):
    raise ex

class Context:

    def halt(self):
        self._rvd.writeInt(self._DCR, 1, 0x09)
        return

    def reset(self):
        self.halt()
        #set general regs to 0
        for reg in range(64):
            self.CREG_GPREG[reg] = 0
        #reset
        self._rvd.writeInt(self._DCR, 1, 0x80)

    def resume(self):
        self._rvd.writeInt(self._DCR, 1, 0x0c)

    def step(self):
        self._rvd.writeInt(self._DCR, 1, 0x0a)
    
    def get_perf_counter(self, addr):
        d = self._rvd.readIntMultiple(addr, 4, 2)
        if len(d) != 2:
            raise RuntimeError('read access failed')
        lo = d[0]
        hi = d[1]
        res = 0
        if self._core.FIELD_EXT0_P > 4:
            if (lo >> 24) != (hi & 0xff):
                res = hi << 24
            else:
                res = (hi << 24) | lo
        else:
            res = lo
        return res
    
    def get_perf_counters(self):
        """Return a dict mapping counter names to values.
        """
        names = ['CYC', 'CYCH', 'STALL', 'STALLH', 'BUN', 'BUNH', 'SYL', 'SYLH',
                 'NOP', 'NOPH', 'IACC', 'IACCH', 'IMISS', 'IMISSH', 'DRACC',
                 'DRACCH', 'DRMISS', 'DRMISSH', 'DWACC', 'DWACCH', 'DWMISS',
                 'DWMISSH', 'DBYPASS', 'DBYPASSH', 'DWBUF', 'DWBUFH']
        result = OrderedDict()
        for name in names:
            result[name] = self.get_perf_counter(getattr(self, '_{}'.format(name)))
        return result

    class GPREGS:

        def __init__(self, c):
            self._c = c

        def __getitem__(self, index):
            return self._c._rvd.readInt(self._c._CREG_GPREG + index*4, 4)

        def __setitem__(self, index, value):
            self._c._rvd.writeInt(self._c._CREG_GPREG + index*4, 4, value)

    def __init__(self, rvd, core, base_address, index):
        self._rvd = rvd
        self._core = core
        self._CREG = base_address
        self._CUR_CONTEXT = index

        self._CREG_GPREG = self._CREG + 0x100 + (self._CUR_CONTEXT * 0x400)
        self.CREG_GPREG = self.GPREGS(self)

        self._CREG_CTXT = self._CREG + 0x200 + (self._CUR_CONTEXT * 0x400)
@CTXT_REGISTER_ADDR
        return


@CTXT_REGISTER_PROP

class Core:

    def __iter__(self):
        for c in self.context:
            yield c

    def __getitem__(self, index):
        return self.context[index]

    def __init__(self, rvd, base_address):
        self._rvd = rvd
        self._CREG_GLOB = base_address
@CORE_REGISTER_ADDR
        self.context = [Context(rvd, self, base_address, x) for x in
                range(self.FIELD_DCFG_NC+1)]
        return

@CORE_REGISTER_PROP

