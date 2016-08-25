import socket
import re
import argparse

class Rvd:
    """A class for handling the communication protocol with rvsrv.
    Has methods for sending read, write and stop commands to rvsrv.
    Here is a description of the protocol for communicating with rvsrv:

    Tokenization
    ------------

     * All characters not in [,;a-zA-Z0-9] are completely ignored.
     * Packet delimiter = ';'
     * Parameter delimiter = ','
     * The client always sends a command first, then rvsrv will send a reply as soon
       as possible.

    Structure of all replies
    ------------------------

     * Error reply: "Error,<cmd>,<code>;"
       <cmd> equals the first parameter of the command.
       <code> is some command-dependent error message name. rvd just prints
       whatever's in there when an error is received.

     * Acknowledgement: "OK,<cmd>[...];"
       <cmd> equals the first parameter of the command.
       [...] is a command-dependent reply.

    Defined commands
    ----------------

    Stop command:      "Stop;"
      OK reply:        "OK,Stop;"

    This command requests that rvsrv be stopped.


    Bus read command:  "Read,<addr>,<count>;"
      OK reply:        "OK,Read,OK,<addr>,<count>,<data>;"
      Fault reply:     "OK,Read,Fault,<addr>,<count>,<code>;"

    Bus write command: "Write,<addr>,<count>,<data>;"
      OK reply:        "OK,Write,OK,<addr>,<count>;"
      Fault reply:     "OK,Write,Fault,<addr>,<count>,<code>;"

    NOT YET IMPLEMENTED:
    ROM read command:  "ROM,<addr>,<count>;"
      OK reply:        "OK,ROM,OK,<addr>,<count>,<data>;"

    <addr> is an 8-digit hex number specifying the start address.
    <count> is a decimal integer between 1 and 4096, specifying the number of
    bytes to read/write.
    <data> is a hex array, <count>*2 in length, specifying the read/write data.
    <code> is an 8-digit hex number specifying the bus fault code.

    1, 2 and 4 byte read/writes are guaranteed to be in-order and atomic. Larger
    read/writes may be read/written one or more times in any order, and bus fault
    detection is best-effort only.

    ROM read commands work the same way as normal reads, but they will go to the
    debug support unit ROM instead of the bus. This ROM is supposed to contain
    version information stuff.

    """

    def recv_all(self):
        """Receive all data from the socket until there is no more data to
        receive and return it as a string.
        """
        chunk_size = 4096
        msg = bytearray()
        while True:
            chunk = self.socket.recv(chunk_size)
            msg.extend(chunk)
            if len(chunk) == 0:
                return None
            if b';' in chunk:
                break
        return re.sub(r'[^,;a-zA-Z0-9]','', msg.decode('utf-8'))


    def stop(self):
        """Send the stop command to rvsrv.
        """
        command = "Stop;".encode('utf-8')
        res = self.socket.send(command)
        res = self.recv_all()
        match = re.match(r'OK,Stop;', res)
        if not match:
            return None
        return True


    def write(self, address, data):
        """Write the bytearray data to rvsrv.
        Returns the number of bytes successfully written, or None if the server
        did not respond.
        
        Split the data into chunks of size 4096 before sending, because that is
        what rvsrv expects.
        """
        chunk_size = 4*1024
        bytes_sent = 0
        while len(data) - bytes_sent > 0:
            # offset from start of alignment
            offset = address % chunk_size
            # number of bytes in chunk
            bytes_to_send = min(chunk_size - offset, len(data) - bytes_sent)
            chunk = data[bytes_sent:bytes_sent + bytes_to_send]
            command = "Write,{:08x},{:d},{};".format(address + bytes_sent,
                    len(chunk),
                    ''.join('{:02x}'.format(x) for x in chunk)).encode('utf-8')
            res = self.socket.send(command)
            res = self.recv_all()
            match = re.match(r'OK,Write,(?P<mode>OK|Fault),(?P<addr>[0-9a-zA-Z]+),'+
                    '(?P<count>[0-9]+)(?:,(?P<data>[0-9a-zA-Z]+))?;', res)
            if not match:
                return None
            if not match.group('mode') == 'OK':
                break
            bytes_sent += len(chunk)
        return bytes_sent

    def writeInt(self, address, count, data):
        """Converts the integer value data into an array of bytes of length
        count and writes them to address.
        Raises an exception on failure.
        """
        res = self.write(address, data.to_bytes(count, byteorder='big'))
        if res == count:
            return
        raise RuntimeError('write access failed: {}'.format(res))


    def read(self, address, count):
        """Reads count bytes from address and return a tupple containing the
        result in the following format:
        (code, addr, count, data)
        Where code is either 'OK', or 'Fault', addr is the address given as
        input, count is the number of bytes that were to be read, and data
        contains the bytes read in the case of success, and the error code
        in the case of failure.
        """
        command = "Read,{:08x},{:d};".format(address, count).encode('utf-8')
        res = self.socket.send(command)
        res = self.recv_all()
        match = re.match(r'OK,Read,(?P<mode>OK|Fault),(?P<addr>[0-9a-zA-Z]+),'
                r'(?P<count>[0-9]+),(?P<data>[0-9a-zA-Z]+);', res)
        if not match:
            return None
        return (match.group('mode'), int(match.group('addr'), 16),
                int(match.group('count')),
                bytearray.fromhex(match.group('data')))

    def readInt(self, address, count):
        """Reads count bytes from the given address and converts the result
        into an integer value before returning it.
        Raises an exception if the read access failed.
        """
        res = self.read(address, count)
        if res[0] == 'OK':
            return int.from_bytes(res[3], byteorder='big')
        raise RuntimeError('read access failed: {}'.format(res))


    def __init__(self, host='localhost', port=21079):
        self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.socket.connect((host, port))

    def __enter__(self):
        return self


    def __exit__(self, exc_type, exc_val, exc_tb):
        self.socket.close()


def main():
    parser = argparse.ArgumentParser(description='Send rvd commands')
    parser.add_argument('--port', type=int, default=21079,
            help="""Port number.""")
    parser.add_argument('--host', type=str, default='localhost',
            help="""Host the server is running on.""")
    args = parser.parse_args()
    with Rvd(args.host, args.port) as rvd:
        print(rvd.write(4, 4, bytearray.fromhex('cafebabe')))
        print(rvd.read(4, 4))


if __name__ == "__main__":
    main()

