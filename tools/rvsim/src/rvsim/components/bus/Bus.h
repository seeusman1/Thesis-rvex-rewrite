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

#ifndef RVSIM_COMPONENTS_BUS_BUS_H
#define RVSIM_COMPONENTS_BUS_BUS_H

#include <inttypes.h>
#include "../Simulation.h"

#include <vector>

using namespace std;

namespace Bus {

//==============================================================================
// Bus transfer lifetime
//==============================================================================
//
//  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Clock    .-------------------------.
//          | Request setup by master |<----------.
//          '-------------------------'           |
//  - - - - - - - - - - -|- - - - - - - - - - -   |
// Sync                  |    (request phase)  :  |
//                       v                     :  |
//          .-------------------------.        :  |
//          |     Bus arbitration     |        :  |
//          '-------------------------'        :  |
//       lost |          ^          | won      :  |
//            v          |          v          :  |
//     .--------------.  |   .--------------.  :  |
//     | Request nack |  |   | Request ack  |  :  | next pipelined
//     '--------------'  |   '--------------'  :  | transfer
//  - - - - - | - - - -  |          |          :  |
// Clock      v        : |          v          :  |
//     .--------------.: |   .--------------.  :  |
//     | Master stall |: |   |  Bus passes  |  :  |
//     '--------------': |   |  pointer to  |  :  |
//  - - - - - | - - - -  |   | transfer to  |  :  |
// Sync       '----------'   |    slave     |  :  |
//                           '--------------'  :  |
//  - - - - - - - - - - - - - - - - | - - - - -   |
// Clock                            o-------------'
//        (response phase)          |
//                                  v
//          .-------------------------.
//          |     Slave processing    |
//          '-------------------------'
//   BSS_BUSY |          ^          | BSS_OK or
//  - - - - - | - - - -  |          | BSS_FAULT
// Sync       v        : |          |
//     .--------------.: |          |
//     | All masters  |: |          |
//     | lose arbitr. |: |          |
//     '--------------': |          |
//  - - - - - | - - - -  |          |
// Clock      v          |          |
//     .--------------.  |          |
//     | Master stall |  |          |
//     '--------------'  |          |
//            '----------'          |
//  - - - - - - - - - - - - - - - - | - - - - - - - - - - - - - - - - - - - - -
// Sync                             v
//                           .--------------.
//     .----------------.    |  Bus copies  |
//     | Bus arbitrates |<---| response to  |
//     |  next request  |    |    master    |
//     '----------------'    '--------------'
//  - - - - - | - - - - - - - - - -   - - - - - - - - - - - - - - - - - - - - -
// Clock      v
//          .-------------------------.
//          | Response used by master |
//          '-------------------------'
//
//
//==============================================================================
// Bus master tasks in clock()
//==============================================================================
//
//  - The master.request.state variable must be driven by the master. If it is
//    driven to something other than BQS_IDLE, master.request.address and
//    master.request.mask must also be driven appropriately. If
//    master.request.mask is nonzero, master.request.data must also be driven.
//
//  - The master should keep its request stable until master.request.ack is set
//    by the bus. Basically, it should stall if !master.request.ack.
//
//  - In the clock cycle(s) after the request was acknowledged, the master must
//    check master.response->state. If this is BSS_OK or BSS_FAULT, the response
//    is valid. If it is BSS_BUSY, the master should probably stall.
//
//  - The response of a bus transfer is only valid during one call to clock().
//    If the master is stalled during that cycle for some other reason, it
//    should probably store the result in an intermediate buffer (register),
//    just like the HDL model would have to.
//
//
//==============================================================================
// Bus slave tasks in clock()
//==============================================================================
//
//  - If slave.request is nonzero, handle the request it points to.
//
//  - When the slave finishes handling the request, drive slave.response.state
//    to BSS_OK or BSS_FAULT and set data appropriately.
//
//  - If slave.request is zero, the bus may drive slave.response.state to
//    BSS_IDLE, but it doesn't have to, because the value is never used in this
//    case.
//
//  - The slave is allowed to, but does not explicitely have to drive
//    slave.response.state to BSS_BUSY. The bus will initialize the response as
//    such.
//
//
//==============================================================================
// Bus request structures
//==============================================================================

/**
 * Enumeration for the types of bus requests.
 */
typedef enum busRequestState_t {

	/**
	 * No bus access.
	 */
	BQS_IDLE,

	/**
	 * Normal bus access. When complete, the bus may switch to another master.
	 */
	BQS_SINGLE,

	/**
	 * First transfer in a burst. This should prepare the slave for receiving
	 * subsequent requests to contiguous memory. Bursts may not cross 1kiB
	 * boundaries. The bus will not attempt to switch to another master during
	 * the cycle where the response is delivered.
	 */
	BQS_BURST_START,

	/**
	 * Continuation of a burst. Semantics are the same as BRM_BURST_START
	 * otherwise.
	 */
	BQS_BURST_CONT,

	/**
	 * Locks the bus. This will prevent the bus from switching to another
	 * master.
	 */
	BQS_LOCK

} busRequestState_t;

/**
 * Bus request data structure.
 */
typedef struct busRequest_t {

	// --- Request, written by master ---

	/**
	 * Bus request type.
	 */
	busRequestState_t state;

	/**
	 * Request word address.
	 */
	uint32_t address;

	/**
	 * Write mask. Bit 3 corresponds to the MSB of data. If zero, this is a
	 * read.
	 */
	uint8_t mask;

	/**
	 * Write data.
	 */
	uint32_t data;


	// --- Request ack, written by bus ---

	/**
	 * This is set when the request is acknowledged by the bus, which means that
	 * a new request can be made.
	 */
	uint8_t ack;

} busRequest_t;


//==============================================================================
// Bus response structures
//==============================================================================

/**
 * Bus response state enumeration.
 */
typedef enum busResponseState_t {

	/**
	 * No transfer in progress.
	 */
	BSS_IDLE,

	/**
	 * Transfer in progress.
	 */
	BSS_BUSY,

	/**
	 * Transfer completed successfully.
	 */
	BSS_OK,

	/**
	 * Transfer completed with a fault, readData contains fault code.
	 */
	BSS_FAULT

} busResponseState_t;

/**
 * Forward declaration for bus master structure.
 */
typedef struct busMaster_t busMaster_t;

/**
 * Bus response structure.
 */
typedef struct busResponse_t {

	/**
	 * Response to the request above.
	 */
	busResponseState_t state;

	/**
	 * For which master this response is intended.
	 */
	const busMaster_t *master;

	/**
	 * Response data.
	 */
	uint32_t data;

} busResponse_t;


//==============================================================================
// Bus snooping structures
//==============================================================================

typedef struct busSnoop_t {

	/**
	 * Request word address.
	 */
	uint32_t address;

	/**
	 * Write mask. Bit 3 corresponds to the MSB of data. If zero, this is a
	 * read.
	 */
	uint8_t mask;

} busSnoop_t;


//==============================================================================
// Bus endpoint structures
//==============================================================================

/**
 * Bus master structure.
 */
typedef struct busMaster_t {

	/**
	 * Bus request for this master.
	 */
	busRequest_t request;

	/**
	 * Bus response. The response is only intended for this master if
	 * response->master points to this struct.
	 */
	const busResponse_t *response = 0;

	/**
	 * Address and write mask to go along with the response for bus snooping.
	 */
	const busSnoop_t *snoop = 0;

} busMaster_t;

/**
 * Bus slave structure.
 */
typedef struct busSlave_t {

	/**
	 * Bus request from the master, or 0 if there is no pending or ongoing
	 * request.
	 */
	const busRequest_t *request = 0;

	/**
	 * Bus response.
	 */
	busResponse_t response;

} busSlave_t;

/**
 * Demuxer function. Should return a negative value if this address does not
 * belong to the given slave. If it does belong, it should return the address
 * which is to be forwarded to the slave.
 */
typedef int64_t (*busDemuxFunPtr_t)(busSlave_t *slave, uint32_t address,
		void *param);

/**
 * Slave demuxer configuration.
 */
typedef struct busDemuxEntry_t {

	/**
	 * The slave for this entry.
	 */
	busSlave_t *slave;

	/**
	 * Bus demuxing function.
	 */
	busDemuxFunPtr_t fun;

	/**
	 * Parameter to pass to the bus demuxing function.
	 */
	void *param;

} busDemuxEntry_t;


//==============================================================================
// Bus controller entity
//==============================================================================

class Bus : public Entity {
private:

	/**
	 * Current bus request, in the address space of the current slave.
	 */
	busRequest_t currentRequest;

	/**
	 * Same address as what's in currentRequest, but in the address space of the
	 * masters.
	 */
	uint32_t currentOrigAddr;

	/**
	 * Current bus response.
	 */
	busResponse_t currentResponse;

	/**
	 * Current bus snooping data.
	 */
	busSnoop_t currentSnoop;

	/**
	 * Slave which is servicing the current request, or 0 if the bus is idle.
	 */
	busSlave_t *currentSlave;

	/**
	 * Index of the master which last won arbitration.
	 */
	int currentMasterIdx;

	/**
	 * List of masters.
	 */
	vector<busMaster_t*> masters;

	/**
	 * List of slaves.
	 */
	vector<busDemuxEntry_t> slaves;

	/**
	 * Dummy slave, selected whenever a request is made to an unmapped address.
	 */
	busSlave_t unmapped;

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
	 * Finds the slave which is mapped to the given address and mutates the
	 * address to put it in the slave address space.
	 */
	busSlave_t *demux(uint32_t *address);

public:

	/**
	 * Creates a new bus controller.
	 */
	Bus(const char *name);

	/**
	 * Destroys this bus controller.
	 */
	virtual ~Bus();

	/**
	 * Adds a master to the bus. May not be called after clock() or
	 * synchronize() are called.
	 */
	void addMaster(busMaster_t *master);

	/**
	 * Adds a slave to the bus. May not be called after clock() or
	 * synchronize() are called.
	 */
	void addSlave(busSlave_t *slave, busDemuxFunPtr_t demuxFun, void *param);

};

} /* namespace Bus */

#endif
