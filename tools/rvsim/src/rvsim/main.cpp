#include <stdio.h>
#include <unistd.h>
#include <string.h>

#include "utils/DebugServer.h"
#include "utils/VirtualMemory.h"
#include "components/Simulation.h"
#include "components/bus/Bus.h"
#include "components/periph/Memory.h"
#include "components/periph/DebugPort.h"

using namespace std;

static int64_t demuxMemory(Bus::busSlave_t *slave, uint32_t address) {
	if (address < 0x80000000) {
		return address;
	} else {
		return -1;
	}
}

int main(int argc, char **argv) {

	Simulation sim;

	// Bus.
	Bus::Bus bus("busModel");
	sim.add(&bus);

	// Debug "UART".
	Periph::DebugPort debugPort("debugPort", 21079);
	bus.addMaster(&debugPort);
	sim.add(&debugPort);

	// Main memory, 512 MiB.
	Periph::Memory memory("memModel", 29, 0);
	memory.setLatency(100);
	memory.setPeriod(0);
	memory.setBurstBoundary(8);

	bus.addSlave(&memory, demuxMemory);
	sim.add(&memory);

	// Run the simulation.
	sim.run();
	return 0;

}


#if 0

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
	virtual void handleAccess(pendingAccess_t *access) {
		if (access->type == 0) {
			mem.access(access->address, access->buffer, access->numBytes,
					access->direction);
			finishBusAccess(AR_OK);
		} else {
			finishBusAccess(AR_ERROR);
		}
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
	DebugServerTest() : DebugServer("debug"), stopped(0), mem(32, 0) {};

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

#endif

