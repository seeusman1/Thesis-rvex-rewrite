#!/usr/bin/env python3
import argparse
import sys
import elftools.elf.elffile as elffile
from pyrvd import Rvd, Core
from time import sleep
import socket
import datetime

def upload_child_args(rvd, args, argc, argv, argv_end):
    """Write the arguments for the program to the addresses specified by argc,
    argv and argv_end.

    Program exits if args is larger than the space available.
    """
    # convert strings to bytearrays and add 0 termination
    data = []
    for arg in args:
        val = bytearray(arg.encode('utf-8'))
        val.append(0)
        data.append(val)
    # check if args fit in available space
    size = 4*(len(data)+1)
    for arg in data:
        size += len(arg)
    if size > (argv_end - argv):
        print('child args too large', file=sys.stderr)
        exit(1)
    # write argc into memory
    rvd.writeInt(argc, 4, len(data))
    # skip argc + 1 address size spaces
    offset = 4*(len(data) + 1)
    for index, arg in enumerate(data):
        rvd.writeInt(argv + index*4, 4, argv + offset)
        # write string to memory
        rvd.write(argv + offset, arg)
        offset += len(arg)

def allDone(core):
    """Return True if all active contexts are done."""
    cc = core.CC
    active = set('{:0{width}x}'.format(cc, width=len(core.context)))
    for c in active:
        if core[int(c, 16)].FIELD_DCR_D == 0:
            return False
    return True

def main():
    parser = argparse.ArgumentParser(description="""Run programs on FPGA as if
                                     they were run in the simulator.""")
    parser.add_argument('--init',
                        type=lambda x: int(x, 16),
                        default = 0,
                        help='Initial rVEX configuration.')
    parser.add_argument('filename',
                        help='Program to run on rVEX.')
    parser.add_argument('child_args', nargs=argparse.REMAINDER)
    args = parser.parse_args()
    rvd = Rvd()
    core = Core(rvd, 0xd0000000)
    core.BCRR = 0
    for context in core:
        context.halt()
        context.reset()
    with open(args.filename, 'rb') as f:
        child_args = {'__argc':None, '__argv':None, '__argv_end':None}
        child_args_found = True
        ef = elffile.ELFFile(f)
        # got this value from elf.h
        SHF_ALLOC = 0x2
        for section in ef.iter_sections():
            if (section['sh_type'] == 'SHT_PROGBITS' and
                    section['sh_flags'] & SHF_ALLOC):
                print('Uploading {} section'.format(section.name),
                        file=sys.stderr)
                rvd.write(section['sh_addr'], section.data())
            elif section['sh_type'] == 'SHT_SYMTAB':
                for name in child_args.keys():
                    sym = section.get_symbol_by_name(name)
                    if sym:
                        child_args[name] = sym[0]['st_value']
                    else:
                        child_args_found = False
        if child_args_found:
            # add program name to start of args
            args.child_args.insert(0, args.filename)
            upload_child_args(rvd, args.child_args, child_args['__argc'],
                    child_args['__argv'], child_args['__argv_end'])
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.connect(('localhost', 21078))
        print('start', datetime.datetime.now(), file=sys.stderr)
        core[0].resume()

        while True:
            try:
                data = s.recv(1024, socket.MSG_DONTWAIT)
                if len(data) > 0:
                    print(data.decode('latin-1'), end='')
                    continue
                else:
                    sleep(1)
            except BlockingIOError:
                sleep(1)
            if allDone(core):
                break
        s.close()
        for context in core:
            perf = context.get_perf_counters()
            print('Context:', context._CUR_CONTEXT)
            for counter in perf.keys():
                print('\t{}: {}'.format(counter, perf[counter]))
        print('end', datetime.datetime.now(), file=sys.stderr)


if __name__ == '__main__':
    main()
