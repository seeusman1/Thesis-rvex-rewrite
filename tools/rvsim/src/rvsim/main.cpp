#include <stdio.h>
#include <unistd.h>
#include <string.h>

#include "utils/DebugServer.h"
#include "utils/VirtualMemory.h"
#include "components/Simulation.h"
#include "components/bus/Bus.h"
#include "components/periph/Memory.h"
#include "components/periph/DebugPort.h"
#include "components/core/System.h"

using namespace std;

static int64_t demuxMemory(Bus::busSlave_t *slave, uint32_t address,
		void *param)
{
	if (address < 0x80000000) {
		return address;
	} else {
		return -1;
	}
}

static int64_t demuxDebugBus(Bus::busSlave_t *slave, uint32_t address,
		void *param)
{
	if ((address & 0xFFFF0000) == 0xD0000000) {
		return address;
	} else {
		return -1;
	}
}

class NullMemorySystem : public Core::MemorySystem {
protected:
	virtual int init() { return 0; };
	virtual void preClockPreStall() { };
	virtual void preClockPostStall() { };
	virtual void postClock() { };
	virtual int synchronize() { return 0; };
	virtual int occasional() { return 0; };
	virtual void fini() { };
public:
	NullMemorySystem() {};
	virtual ~NullMemorySystem() {};
};



int main(int argc, char **argv) {

	Simulation sim;

	// Bus.
	Bus::Bus bus("busModel");
	sim.add(&bus);

	// Core.
	Core::coreInterfaceGenerics_t gen;
	gen.CFG.numLanesLog2          = 3;
	gen.CFG.numLaneGroupsLog2     = 2;
	gen.CFG.numContextsLog2       = 2;
	gen.CFG.genBundleSizeLog2     = 3;
	gen.CFG.bundleAlignLog2       = 1;
	gen.CFG.multiplierLanes       = 0xFF;
	gen.CFG.memLaneRevIndex       = 1;
	gen.CFG.numBreakpoints        = 4;
	gen.CFG.forwarding            = 1;
	gen.CFG.limmhFromNeighbor     = 1;
	gen.CFG.limmhFromPreviousPair = 0;
	gen.CFG.reg63isLink           = 0;
	gen.CFG.cregStartAddress      = 0xFFFFFC00;
	gen.CFG.resetVectors[0]       = 0;
	gen.CFG.resetVectors[1]       = 0;
	gen.CFG.resetVectors[2]       = 0;
	gen.CFG.resetVectors[3]       = 0;
	gen.CFG.resetVectors[4]       = 0;
	gen.CFG.resetVectors[5]       = 0;
	gen.CFG.resetVectors[6]       = 0;
	gen.CFG.resetVectors[7]       = 0;
	gen.CFG.unifiedStall          = 0;
	gen.CFG.traceEnable           = 0;
	gen.CFG.perfCountSize         = 7;
	gen.CFG.cachePerfCountEnable  = 1;
	gen.CORE_ID                   = 0;
	gen.PLATFORM_TAG              = 0;
	NullMemorySystem memSys;
	Core::System rvexSystem("r-VEX", &gen, &memSys, &bus, demuxDebugBus, 0);
	sim.add(&rvexSystem);

	// Main memory, 512 MiB.
	Periph::Memory memory("memModel", 29, 0);
	memory.setLatency(100);
	memory.setPeriod(0);
	memory.setBurstBoundary(8);
	bus.addSlave(&memory, demuxMemory, 0);
	sim.add(&memory);

	// Debug "UART".
	Periph::DebugPort debugPort("debugPort", 21079);
	bus.addMaster(&debugPort);
	sim.add(&debugPort);


	// Run the simulation.
	sim.run();
	return 0;

}

