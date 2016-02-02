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

#include "Updaters.h"
#include "MtiHelper.h"

#include <inttypes.h>
#include <string.h>
#include <mti.h>
#include "../rvsim/components/rvex/Core.h"


//==============================================================================
// Generic port stuff.
//==============================================================================

/**
 * Adds a port entry to a port list and returns a pointer to the entry.
 */
static updatedPort_t *addPort(updatedPortList_t *portList) {

	// Reallocate the port list if necessary.
	if (portList->count >= portList->capacity) {
		if (portList->capacity == 0) {
			portList->capacity = 8;
			portList->l = (updatedPort_t*)mti_Malloc(
					portList->capacity * sizeof(updatedPort_t));
		} else {
			portList->capacity *= 2;
			portList->l = (updatedPort_t*)mti_Realloc(portList->l,
					portList->capacity * sizeof(updatedPort_t));
		}
	}

	// Increment the count and return the new port.
	return portList->l + portList->count++;

}


//==============================================================================
// Input port stuff.
//==============================================================================

/**
 * Input update function for an std_logic.
 */
static void readStdLogic(void *param) {
	updatedPort_t *port = (updatedPort_t*)param;

	// Get the VHDL signal value.
	mtiInt32T val = mti_GetSignalValue(port->signal);

	// std_logic enum entry 3 is '1', 7 is 'H'.
	*((uint8_t*)(port->cdata)) = (val == 3) || (val == 7);

}

/**
 * Input update function for an std_logic_vector.
 */
static void readStdLogicVector(void *param) {
	updatedPort_t *port = (updatedPort_t*)param;
	int count = port->vlen;

	// Get the VHDL signal value.
	mti_GetArraySignalValue(port->signal, port->vdata);

	// Loop over the array. The VHDL arrays start at the MSB.
	uint64_t val = 0;
	for (int i = 0; i < count; i++) {

		// std_logic enum entry 3 is '1', 7 is 'H'.
		if (port->vdata[i] == 3 || port->vdata[i] == 7) {
			val |= 1 << (count-i-1);
		}

	}

	// Store the value.
	if (count > 32) {
		*((uint64_t*)(port->cdata)) = val;
	} else if (count > 16) {
		*((uint32_t*)(port->cdata)) = (uint32_t)val;
	} else if (count > 8) {
		*((uint16_t*)(port->cdata)) = (uint16_t)val;
	} else {
		*((uint8_t*)(port->cdata)) = (uint8_t)val;
	}

}

/**
 * Internal input add function.
 */
static int addInput_int(updatedPortList_t *portList,
		mtiSignalIdT signal, char *cdata, const char *typeHint)
{

	// Figure out the port type.
	mtiTypeIdT type = mti_GetSignalType(signal);
	switch (mti_GetTypeKind(type)) {

	case MTI_TYPE_ENUM: {
		int n = mti_TickLength(type);
		if (n == 9) {

			//mti_PrintMessage("   Found std_logic.");

			// This seems to be an std_logic.
			updatedPort_t *port = addPort(portList);
			port->signal = signal;
			port->driver = 0;
			port->cdata = cdata;
			port->vdata = 0;
			port->vlen = 0;
			port->update = readStdLogic;
			return 1;

		}
		break;
	}

	case MTI_TYPE_ARRAY: {
		mtiTypeIdT atype = mti_GetArrayElementType(type);
		int count = mti_TickLength(type);
		switch (mti_GetTypeKind(atype)) {

		case MTI_TYPE_ENUM: {
			if (mti_TickLength(atype) == 9) {

				//mti_PrintFormatted("   Found std_logic_vector<%d>.\n", count);

				// This seems to be an std_logic_vector of size count.
				int cdata_needed = 1;
				if (count > 32) {
					cdata_needed = 8;
				} else if (count > 16) {
					cdata_needed = 4;
				} else if (count > 8) {
					cdata_needed = 2;
				}

				updatedPort_t *port = addPort(portList);
				port->signal = signal;
				port->driver = 0;
				port->cdata = cdata;
				port->vdata = (char*)mti_Malloc(count);
				port->vlen = count;
				port->update = readStdLogicVector;
				return cdata_needed;

			}
			break;
		}

		case MTI_TYPE_RECORD:
		case MTI_TYPE_ARRAY: {

			//mti_PrintMessage("   Found array.");

			// An array of some kind; recurse.
			mtiSignalIdT *se = mti_GetSignalSubelements(signal, 0);
			int cdata_needed = 0;
			for (int i = count-1; i >= 0; i--) {
				int n = addInput_int(portList, se[i], cdata, typeHint);
				cdata += n;
				cdata_needed += n;
			}
			mti_VsimFree(se);
			return cdata_needed;
		}

		default:
			break;
		}
		break;
	}

	case MTI_TYPE_RECORD: {
		int count = mti_GetNumRecordElements(type);
		if (!typeHint) {
			break;
		}
		if (!strcmp(typeHint, "cacheStatus")) {
			if (count != 6) {
				break;
			}

			//mti_PrintMessage("   Found rvex_cacheStatus_type.");

			// This seems to be an rvex_cacheStatus_type record.
			typedef struct {
			    uint8_t instr_access;
			    uint8_t instr_miss;
			    uint8_t data_accessType;
			    uint8_t data_bypass;
			    uint8_t data_miss;
			    uint8_t data_writePending;
			} cacheStatus_t;
			cacheStatus_t *cs = (cacheStatus_t*)cdata;
			mtiSignalIdT *se = mti_GetSignalSubelements(signal, 0);

			if (addInput_int(portList, se[0],
					(char*)&(cs->instr_access), 0) != 1) goto oor;

			if (addInput_int(portList, se[1],
					(char*)&(cs->instr_miss), 0) != 1) goto oor;

			if (addInput_int(portList, se[2],
					(char*)&(cs->data_accessType), 0) != 1) goto oor;

			if (addInput_int(portList, se[3],
					(char*)&(cs->data_bypass), 0) != 1) goto oor;

			if (addInput_int(portList, se[4],
					(char*)&(cs->data_miss), 0) != 1) goto oor;

			if (addInput_int(portList, se[5],
					(char*)&(cs->data_writePending), 0) != 1) goto oor;

			mti_VsimFree(se);
			return sizeof(cacheStatus_t);
		}

		break;
	}

	default:
		break;
	}

	// Error handling...
	mti_PrintFormatted("FATAL: input signal %s: ",
			mti_GetSignalName(signal));
	mti_PrintFormatted("unsupported VHDL type. Code = %d.\n",
			mti_GetTypeKind(type));
	mti_FatalError();
	oor:
	mti_PrintFormatted("FATAL: input signal %s: C buffer not the right size.\n",
			mti_GetSignalName(signal));
	mti_FatalError();
	return 0;
}

/**
 * Adds an input to a managed process. If sensitize is nonzero, the signal is
 * also added to the process sensitivity list.
 */
void updaters_addInput(updatedProcess_t *proc, mtiSignalIdT signal,
		void *cdata, int sizeof_cdata, const char *typeHint, int sensitize)
{

	//mti_PrintFormatted("SCANNING SIGNAL %s.\n", mti_GetSignalName(signal));

	// Find out which input list to add the signal to and sensitize the process
	// if necessary.
	updatedPortList_t *portList;
	if (sensitize) {
		mti_Sensitize(proc->pid, signal, MTI_EVENT);
		portList = &(proc->ins);
	} else {
		portList = &(proc->inn);
	}

	// Add the port.
	int cdata_needed = addInput_int(portList, signal, (char*)cdata, typeHint);

	// Make sure that the size of the C data matches what we would expect,
	// because if it doesn't, the VHDL and C code are probably very much out of
	// sync.
	if (cdata_needed > sizeof_cdata) {
		mti_PrintFormatted("FATAL: input signal %s: ",
				mti_GetSignalName(signal));
		mti_PrintFormatted("C buffer not the right size. actual size %d, derived %d.\n",
				sizeof_cdata, cdata_needed);
		mti_FatalError();
	}

}


//==============================================================================
// Output port stuff.
//==============================================================================

/**
 * Output update function for an std_logic.
 */
static void writeStdLogic(void *param) {
	updatedPort_t *port = (updatedPort_t*)param;

	// Get the C signal value.
	uint8_t val = *((uint8_t*)(port->cdata)) & 1;

	// Schedule the output. std_logic enum entry 2 is '0', 3 is '1'.
	mti_ScheduleDriver(port->driver, val + 2, 0, MTI_INERTIAL);

}

/**
 * Output update function for an std_logic_vector.
 */
static void writeStdLogicVector(void *param) {
	updatedPort_t *port = (updatedPort_t*)param;
	int count = port->vlen;

	// Get the C value.
	uint64_t val;
	if (count > 32) {
		val = *((uint64_t*)(port->cdata));
	} else if (count > 16) {
		val = *((uint32_t*)(port->cdata));
	} else if (count > 8) {
		val = *((uint16_t*)(port->cdata));
	} else {
		val = *((uint8_t*)(port->cdata));
	}

	// Update the VHDL array.
	for (int i = 0; i < count; i++) {

		// std_logic enum entry 2 is '0', 3 is '1'.
		if (val & 1 << (count-i-1)) {
			port->vdata[i] = 3;
		} else {
			port->vdata[i] = 2;
		}

	}

	// Schedule the output.
	mti_ScheduleDriver(port->driver, (long)(port->vdata), 0, MTI_INERTIAL);

}

/**
 * Output update function for a character array.
 */
static void writeString(void *param) {
	updatedPort_t *port = (updatedPort_t*)param;
	int count = port->vlen;

	// Update the VHDL array. cdata is expected to be a null-terminated string,
	// whereas we want to space-fill the VHDL string so it looks nice in the
	// wave viewer.
	const char *c = *((char**)(port->cdata));
	if (c == 0) {
		c = "";
	}
	for (int i = 0; i < count; i++) {
		if (*c) {
			port->vdata[i] = *c++;
		} else {
			port->vdata[i] = ' ';
		}
	}

	// Schedule the output.
	mti_ScheduleDriver(port->driver, (long)(port->vdata), 0, MTI_INERTIAL);

}

/**
 * Internal output add function.
 */
static int addOutput_int(updatedPortList_t *portList, mtiProcessIdT pid,
		mtiSignalIdT signal, char *cdata, const char *typeHint)
{

	// Figure out the port type.
	mtiTypeIdT type = mti_GetSignalType(signal);
	switch (mti_GetTypeKind(type)) {

	case MTI_TYPE_ENUM: {
		int n = mti_TickLength(type);
		if (n == 9) {

			// This seems to be an std_logic.
			mtiDriverIdT driver = mti_CreateDriver(signal);
			mti_SetDriverOwner(driver, pid);

			updatedPort_t *port = addPort(portList);
			port->signal = signal;
			port->driver = driver;
			port->cdata = cdata;
			port->vdata = 0;
			port->vlen = 0;
			port->update = writeStdLogic;
			return 1;

		}
		break;
	}

	case MTI_TYPE_ARRAY: {
		mtiTypeIdT atype = mti_GetArrayElementType(type);
		int count = mti_TickLength(type);
		switch (mti_GetTypeKind(atype)) {

		case MTI_TYPE_ENUM: {
			int enumValCount = mti_TickLength(atype);
			if (enumValCount == 9) {

				// This seems to be an std_logic_vector of size count.
				int cdata_needed = 1;
				if (count > 32) {
					cdata_needed = 8;
				} else if (count > 16) {
					cdata_needed = 4;
				} else if (count > 8) {
					cdata_needed = 2;
				}

				mtiDriverIdT driver = mti_CreateDriver(signal);
				mti_SetDriverOwner(driver, pid);

				updatedPort_t *port = addPort(portList);
				port->signal = signal;
				port->driver = driver;
				port->cdata = cdata;
				port->vdata = (char*)mti_Malloc(count);
				port->vlen = count;
				port->update = writeStdLogicVector;
				return cdata_needed;

			} else if (enumValCount == 256) {

				// This seems to be a character array.
				mtiDriverIdT driver = mti_CreateDriver(signal);
				mti_SetDriverOwner(driver, pid);

				updatedPort_t *port = addPort(portList);
				port->signal = signal;
				port->driver = driver;
				port->cdata = cdata;
				port->vdata = (char*)mti_Malloc(count);
				port->vlen = count;
				port->update = writeString;
				return sizeof(char*);

			}
			break;
		}

		case MTI_TYPE_ARRAY: {

			// An array of some kind; recurse.
			mtiSignalIdT *se = mti_GetSignalSubelements(signal, 0);
			int cdata_needed = 0;
			if (mti_TickLeft(type) < mti_TickRight(type)) {
				for (int i = 0; i < count; i++) {
					int n = addOutput_int(portList, pid, se[i], cdata, typeHint);
					cdata += n;
					cdata_needed += n;
				}
			} else {
				for (int i = count-1; i >= 0; i--) {
					int n = addOutput_int(portList, pid, se[i], cdata, typeHint);
					cdata += n;
					cdata_needed += n;
				}
			}
			mti_VsimFree(se);
			return cdata_needed;
		}

		default:
			break;
		}
		break;
	}

	default:
		break;
	}

	// Error handling...
	mti_PrintFormatted("FATAL: output signal %s: ",
			mti_GetSignalName(signal));
	mti_PrintFormatted("unsupported VHDL type. Code = %d.\n",
			mti_GetTypeKind(type));
	mti_FatalError();
	return 0;

}

/**
 * Adds an output to a managed process.
 */
void updaters_addOutput(updatedProcess_t *proc, mtiSignalIdT signal,
		const void *cdata, int sizeof_cdata, const char *typeHint)
{

	// Add the port.
	int cdata_needed = addOutput_int(
			&(proc->out), proc->pid, signal, (char*)cdata, typeHint);

	// Make sure that the size of the C data matches what we would expect,
	// because if it doesn't, the VHDL and C code are probably very much out of
	// sync.
	if (cdata_needed > sizeof_cdata) {
		mti_PrintFormatted("FATAL: output signal %s: ",
				mti_GetSignalName(signal));
		mti_PrintFormatted("C buffer not the right size. actual size %d, derived %d.\n",
				sizeof_cdata, cdata_needed);
		mti_FatalError();
	}

}


//==============================================================================
// Process stuff.
//==============================================================================

/**
 * Updates all ports in the given list.
 */
static void updatePortList(updatedPortList_t *ports) {
	int remain = ports->count;
	updatedPort_t *port = ports->l;
	while (remain--) {
		port->update(port);
		port++;
	}
}

/**
 * Modelsim callback for a managed process.
 */
static void msimProcessCallback(void *param) {
	updatedProcess_t *proc = (updatedProcess_t*)param;

	// Read the sensitive inputs.
	updatePortList(&(proc->ins));

	// Call the gate function.
	if (proc->gate) {
		if (!proc->gate(proc->core)) {
			return;
		}
	}

	// Read the remaining ports.
	updatePortList(&(proc->inn));

	// Call the update function.
	proc->update(proc->core);

	// Update the signal drivers.
	updatePortList(&(proc->out));

}

/**
 * Creates a managed process.
 */
void updaters_createProcess(updatedProcess_t *proc, const char *name,
		void *core, updatedProcFuncPtr_t update, updatedProcGateFuncPtr_t gate)
{

	// Clear all data.
	memset(proc, 0, sizeof(updatedProcess_t));

	// Create the modelsim process.
	proc->pid = mti_CreateProcessX(name, msimProcessCallback, proc);

	// Set the pointers.
	proc->core = core;
	proc->update = update;
	proc->gate = gate;

}


