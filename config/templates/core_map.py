
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

    class GPREGS:

        def __init__(self, c):
            self._c = c

        def __getitem__(self, index):
            return self._c._rvd.readInt(self._c._CREG_GPREG + index*4, 4)

        def __setitem__(self, index, value):
            self._c._rvd.writeInt(self._c._CREG_GPREG + index*4, 4, value)

    def __init__(self, rvd, base_address, index):
        self._rvd = rvd
        self._CREG = base_address
        self._CUR_CONTEXT = index

        self._CREG_GPREG = self._CREG + 0x100 + (self._CUR_CONTEXT * 0x400)
        self.CREG_GPREG = self.GPREGS(self)

        self._CREG_CTXT = self._CREG + 0x200 + (self._CUR_CONTEXT * 0x400)
@CTXT_REGISTER_ADDR
        return


@CTXT_REGISTER_PROP

class Core:
    def __init__(self, rvd, base_address, num_contexts=4):
        self._rvd = rvd
        self._CREG_GLOB = base_address
        self.context = [Context(rvd, base_address, x) for x in range(num_contexts)]
@CORE_REGISTER_ADDR
        return

@CORE_REGISTER_PROP

