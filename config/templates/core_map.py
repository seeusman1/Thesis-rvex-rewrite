
def raise_(ex):
    raise ex

class Context:

    def __init__(self, rvd, base_address, index):
        self._rvd = rvd
        self._CREG = base_address
        self._CUR_CONTEXT = index

        self._CREG_GPREG = self._CREG + 0x100 + (self._CUR_CONTEXT * 0x400)
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

