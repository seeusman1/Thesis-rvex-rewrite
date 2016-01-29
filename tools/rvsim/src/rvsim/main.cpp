#include <stdio.h>
#include <unistd.h>
#include <string.h>

#include "utils/DebugServer.h"
#include "utils/VirtualMemory.h"

using namespace std;

class DebugServerTest: public DebugServer {
private:

	VirtualMemory mem;

protected:

	/**
	 * Should implement what needs to happen when a bus access is requested by
	 * one of the clients. address is the start address, buffer is the data
	 * buffer, numBytes is the number of bytes to transfer, direction is 1 for
	 * a write and 0 for a read, faultCode is used to return the bus fault code
	 * if one occured. Returns -1 if there is a simulator error, 0 if
	 * successful, or 1 if there was a bus fault.
	 */
	virtual int handleBusAccess(uint32_t address, char *buffer, int numBytes,
			int direction, uint32_t *faultCode) {
		mem.access(address, buffer, numBytes, direction);
		return 0;
	}

	/**
	 * Same as handleBusAccess, but for ROM accesses.
	 */
	virtual int handleRomAccess(uint32_t address, char *buffer, int numBytes) {
		memset(buffer, 0, numBytes);
	}

	/**
	 * Should implement what needs to happen when a client requests the server
	 * be stopped.
	 */
	virtual void handleStop() {
		stopped = 1;
	}

public:

	/**
	 * Whether we've received the stop command yet or not.
	 */
	int stopped;

	/**
	 * Constructs an rvd debug server.
	 */
	DebugServerTest() : DebugServer(), stopped(0), mem(32, 0) {};

	/**
	 * Destroys the server.
	 */
	virtual ~DebugServerTest() {};

};

int main(int argc, char **argv) {

	DebugServerTest server;

	if (server.open(21079)) {
		return 1;
	}

	while (!server.stopped) {
		server.update();
		//usleep(10000);
	}

	return 0;

}

