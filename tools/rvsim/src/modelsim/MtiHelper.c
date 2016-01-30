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

#include "MtiHelper.h"

#include <inttypes.h>
#include <mti.h>
#include <string.h>

/**
 * Creates a process.
 */
mtiProcessIdT mti_CreateProcessX(const char *name,
		mtiVoidFuncPtrT func, void *param)
{
	char *name2 = (char*)mti_Malloc(strlen(name) + 1);
	strcpy(name2, name);
	return mti_CreateProcess(name2, func, param);
	// Note no free. This is because modelsim is silly.

}


/**
 * Finds the specified port in the specified interface list. Throws a fatal
 * error and does not return if the signal does not exist.
 */
mtiSignalIdT mti_FindPortX(mtiInterfaceListT *list, const char *name) {

	char *name2 = (char*)mti_Malloc(strlen(name) + 1);
	strcpy(name2, name);
	mtiSignalIdT sig = mti_FindPort(list, name2);
	mti_Free(name2);

	if (!sig) {
		mti_PrintFormatted("FATAL: could not find port %s.\n", name);
		mti_FatalError();
	}
	return sig;

}

/**
 * Converts a generic value to C, like signalToC() does.
 */
static int valueToC(union mtiGenericValUnion_ val, mtiTypeIdT type, char *buf, int size) {
	switch (mti_GetTypeKind(type)) {

	case MTI_TYPE_SCALAR:
		if (size < 4) goto oor;
		*((int32_t*)buf) = (int32_t)(val.generic_value);
		return 4;

	case MTI_TYPE_ENUM: {
		int n = mti_TickLength(type);
		if (n == 2) {

			// Probably a boolean.
			if (size < 1) goto oor;
			*((uint8_t*)buf) = (uint8_t)(val.generic_value);
			return 1;

		} else if (n == 9) {

			// Probably std_logic. Enum index 3 is '1', enum index 7 is 'H'.
			if (size < 1) goto oor;
			*((uint8_t*)buf) = (val.generic_value == 3) || (val.generic_value == 7);
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

				// Probably std_logic_vector.
				char *data = (char*)(val.generic_array_value);
				uint64_t aval = 0;
				for (int i = 0; i < count; i++) {
					if (data[i] == 3 || data[i] == 7) {
						aval |= 1 << (count-i-1);
					}
				}

				if (count > 32) {
					if (size < 8) goto oor;
					*((uint64_t*)buf) = aval;
					return 8;
				} else if (count > 16) {
					if (size < 4) goto oor;
					*((uint32_t*)buf) = aval;
					return 4;
				} else if (count > 8) {
					if (size < 2) goto oor;
					*((uint16_t*)buf) = aval;
					return 2;
				} else {
					if (size < 1) goto oor;
					*((uint8_t*)buf) = aval;
					return 1;
				}

			}
			break;
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
	mti_PrintFormatted("FATAL: could not read value from generic: ");
	mti_PrintFormatted("unsupported VHDL type.\n", size);
	mti_FatalError();
	oor:
	mti_PrintFormatted("FATAL: could not read value from generic: ");
	mti_PrintFormatted("buffer too small (got %d bytes).\n", size);
	mti_FatalError();
	return 0;
}

/**
 * Reads a generic value into the given buffer. VHDL types natural, boolean,
 * std_logic and std_logic_vector are supported. Returns the number of bytes
 * written.
 */
int genericToC(mtiInterfaceListT *list, const char *name, char *buf, int size) {

	while (list) {
		if (!strcasecmp(list->name, name)) {
			return valueToC(list->u, list->type, buf, size);
		}
		list = list->nxt;
	}

	mti_FatalError();
	return 0;
}

