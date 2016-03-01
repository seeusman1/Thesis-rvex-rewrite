import socket
import re
import argparse

class Rvd:
    """A class for handling a connection to rvsrv.
    Has methods for reading and writhing bytearrays.
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
        """
        command = "Write,{:08x},{:d},{};".format(address, len(data),
                ''.join('{:02x}'.format(x) for x in data)).encode('utf-8')
        res = self.socket.send(command)
        res = self.recv_all()
        match = re.match(r'OK,Write,(?P<mode>OK|Fault),(?P<addr>[0-9a-zA-Z]+),'+
                '(?P<count>[0-9]+)(?:,(?P<data>[0-9a-zA-Z]+))?;', res)
        if not match:
            return None
        return (match.group('mode'), int(match.group('addr'), 16),
                int(match.group('count')), match.group('data'))

    def writeInt(self, address, count, data):
        """Converts the integer value data into an array of bytes of length
        count and writes them to address.
        Raises an exception on failure.
        """
        res = self.write(address, data.to_bytes(count, byteorder='big'))
        if res[0] == 'OK':
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

