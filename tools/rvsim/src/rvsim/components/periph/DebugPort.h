/**
 * r-VEX simulator.
 *
 * Copyright (C) 2008-2015 by TU Delft.
 * All Rights Reserved.
 *
 * THIS IS A LEGAL DOCUMENT, BY USING r-VEX,
 * YOU ARE AGREEING TO THESE TERMS AND CONDITIONS.
 *
 * No portion of this work may be used by any commercial entity, or for any
 * commercial purpose, without the prior, written permission of TU Delft.
 * Nonprofit and noncommercial use is permitted as described below.
 *
 * 1. r-VEX is provided AS IS, with no warranty of any kind, express
 * or implied. The user of the code accepts full responsibility for the
 * application of the code and the use of any results.
 *
 * 2. Nonprofit and noncommercial use is encouraged. r-VEX may be
 * downloaded, compiled, synthesized, copied, and modified solely for nonprofit,
 * educational, noncommercial research, and noncommercial scholarship
 * purposes provided that this notice in its entirety accompanies all copies.
 * Copies of the modified software can be delivered to persons who use it
 * solely for nonprofit, educational, noncommercial research, and
 * noncommercial scholarship purposes provided that this notice in its
 * entirety accompanies all copies.
 *
 * 3. ALL COMMERCIAL USE, AND ALL USE BY FOR PROFIT ENTITIES, IS EXPRESSLY
 * PROHIBITED WITHOUT A LICENSE FROM TU Delft (J.S.S.M.Wong@tudelft.nl).
 *
 * 4. No nonprofit user may place any restrictions on the use of this software,
 * including as modified by the user, by any other authorized user.
 *
 * 5. Noncommercial and nonprofit users may distribute copies of r-VEX
 * in compiled or binary form as set forth in Section 2, provided that
 * either: (A) it is accompanied by the corresponding machine-readable source
 * code, or (B) it is accompanied by a written offer, with no time limit, to
 * give anyone a machine-readable copy of the corresponding source code in
 * return for reimbursement of the cost of distribution. This written offer
 * must permit verbatim duplication by anyone, or (C) it is distributed by
 * someone who received only the executable form, and is accompanied by a
 * copy of the written offer of source code.
 *
 * 6. r-VEX was developed by Stephan Wong, Thijs van As, Fakhar Anjam,
 * Roel Seedorf, Anthony Brandon, Jeroen van Straten. r-VEX is currently
 * maintained by TU Delft (J.S.S.M.Wong@tudelft.nl).
 *
 * Copyright (C) 2008-2015 by TU Delft.
 */

#ifndef RVSIM_COMPONENTS_PERIPH_DEBUGPORT_H
#define RVSIM_COMPONENTS_PERIPH_DEBUGPORT_H

#include "../Simulation.h"
#include "../../utils/DebugServer.h"
#include "../bus/Bus.h"

namespace Periph {

class DebugPort : public Entity, protected DebugServer, public Bus::busMaster_t {
private:

	/**
	 * TCP port number.
	 */
	const int tcpPort;

	/**
	 * Nonzero if a stop was requested by this debug port.
	 */
	int stopped = 0;

	/**
	 * Pending bus access, or 0 if no access is pending.
	 */
	pendingAccess_t *pending = 0;

	/**
	 * Number of requests made.
	 */
	int requestCounter = 0;

	/**
	 * Number of responses received.
	 */
	int responseCounter = 0;

protected:

	/**
	 * Called in preparation for the first clock cycle. The return value should
	 * be 0 for OK or -1 if the simulator should shut down.
	 */
	virtual int init();

	/**
	 * Runs a clock cycle, reading only from inputs and writing only to outputs.
	 * This is called in an OpenMP accelerated loop, so it may be called from
	 * any thread.
	 */
	virtual void clock();

	/**
	 * This should propagate the outputs of this entity to the inputs of other
	 * entities and, if necessary, perform communication with things outside the
	 * simulation. It is only called from the main thread. The return value
	 * should be 0 for OK or -1 if the simulator should shut down.
	 */
	virtual int synchronize();

	/**
	 * Same as synchronize, except that it's only called every n cycles.
	 */
	virtual int occasional();

	/**
	 * Called after the last synchronize() call in the simulation.
	 */
	virtual void fini();

	/**
	 * Called when a debug client wants to access the bus or ROM.
	 */
	virtual void handleAccess(pendingAccess_t *access);

	/**
	 * Called when a debug client wants to stop the simulation.
	 */
	virtual void handleStop();

public:

	/**
	 * Constructs a debug port.
	 */
	DebugPort(const char *name, int tcpPort);

	/**
	 * Destroys the debug port.
	 */
	virtual ~DebugPort();

};

} /* namespace Core */

#endif
