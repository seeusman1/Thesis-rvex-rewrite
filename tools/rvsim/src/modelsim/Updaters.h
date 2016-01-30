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

#ifndef MODELSIM_UPDATERS_H
#define MODELSIM_UPDATERS_H

#include <inttypes.h>
#include <mti.h>

/**
 * Update function pointer type. port points to the port_t structure which is
 * to be updated.
 */
typedef void (*updateFunPtr_t)(void *param);

/**
 * Structure which defines an automatically updated/converted port.
 */
typedef struct {

	/**
	 * Port signal.
	 */
	mtiSignalIdT signal;

	/**
	 * Port driver if this is an output, or 0 if it's an input.
	 */
	mtiDriverIdT driver;

	/**
	 * C data for this port.
	 */
	char *cdata;

	/**
	 * VHDL data for this port if this is an array.
	 */
	char *vdata;

	/**
	 * VHDL array length.
	 */
	int vlen;

	/**
	 * Update function which exchanges between C and VHDL data for this port
	 * type.
	 */
	updateFunPtr_t update;

} updatedPort_t;

/**
 * List of ports.
 */
typedef struct {

	/**
	 * Port list.
	 */
	updatedPort_t *l;

	/**
	 * Number of elements allocated in l.
	 */
	int capacity;

	/**
	 * Number of elements in l.
	 */
	int count;

} updatedPortList_t;

/**
 * Pointer to a process gate function.
 */
typedef int (*updatedProcGateFuncPtr_t)(void *core);

/**
 * Pointer to a process handling function.
 */
typedef void (*updatedProcFuncPtr_t)(void *core);

/**
 * Structure which defines a process, along with a list of automatically
 * updated/converted input and output ports.
 */
typedef struct {

	/**
	 * Sensitive input ports.
	 */
	updatedPortList_t ins;

	/**
	 * Other input ports.
	 */
	updatedPortList_t inn;

	/**
	 * Output ports.
	 */
	updatedPortList_t out;

	/**
	 * Modelsim process ID.
	 */
	mtiProcessIdT pid;

	/**
	 * Pointer to the core structure, passed to the process functions.
	 */
	void *core;

	/**
	 * Process update function.
	 */
	updatedProcFuncPtr_t update;

	/**
	 * Gate function.
	 */
	updatedProcGateFuncPtr_t gate;

} updatedProcess_t;

/**
 * Creates a managed process.
 */
extern void updaters_createProcess(updatedProcess_t *proc, const char *name,
		void *core, updatedProcFuncPtr_t update, updatedProcGateFuncPtr_t gate);

/**
 * Adds an input to a managed process. If sensitize is nonzero, the signal is
 * also added to the process sensitivity list.
 */
extern void updaters_addInput(updatedProcess_t *proc, mtiSignalIdT signal,
		void *cdata, int sizeof_cdata, const char *typeHint, int sensitize);

/**
 * Adds an output to a managed process.
 */
extern void updaters_addOutput(updatedProcess_t *proc, mtiSignalIdT signal,
		const void *cdata, int sizeof_cdata, const char *typeHint);


#endif
