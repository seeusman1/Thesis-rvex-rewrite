/* r-VEX simulator.
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

#include "Simulation.h"

#include <omp.h>
#include <stdio.h>

/**
 * Adds an entity to the simulation.
 */
void Simulation::add(Entity *e) {
	entities.push_back(e);
	e->sim = this;
}

/**
 * Runs the simulation until synchronize() for one of the entities returns -1.
 * e should be a list of pointers to entities, with the last pointer in the list
 * set to 0.
 */
void Simulation::run() {
	int ec;
	int stopped;
	int i, j;

	long long lastCycles;
	double time, lastTime;

	// Determine the number of entities.
	ec = entities.size();

	// Initialize the simulation.
	printf("Starting simulation with the following entities:\n");
	int error = 0;
	for (i = 0; i < ec; i++) {
		printf(" - %s\n", entities[i]->name);
		if (entities[i]->init()) {
			printf("   This entity had some trouble initializing...\n");
			error = 1;
		}
	}
	printf("That's %d entities total.\n\n", ec);

	cycles = 0;
	if (error) {
		printf("One or more entities did not initialize properly.\n");
	} else {

		// Run the simulation loop.
		lastTime = omp_get_wtime();
		lastCycles = 0;
		stopped = 0;
		while (!stopped) {

			// Do performance monitoring.
			time = omp_get_wtime();
			if (time > lastTime + 1.0) {
				double elapsedTime = time - lastTime;
				long long elapsedCycles = cycles - lastCycles;
				lastTime = time;
				lastCycles = cycles;

				double frequency = (double)elapsedCycles / elapsedTime;
				const char *unit = "Hz";
				if (frequency > 1000000.0) {
					unit = "MHz";
					frequency /= 1000000.0;
				} else if (frequency > 1000.0) {
					unit = "kHz";
					frequency /= 1000.0;
				}
				printf("Simulation running at %8.2f %s, at %lld cycles...\n",
						frequency, unit, cycles);
			}

			// Run for 1024 cycles.
			for (j = 0; j < 1024 && !stopped; j++) {

				// Clock cycle.
				//#pragma omp for schedule(dynamic, 1)
				for (i = 0; i < ec; i++) {
					entities[i]->clock();
				}

				// Synchronization and signal propagation.
				for (i = 0; i < ec; i++) {
					if (entities[i]->synchronize() < 0) {
						printf("Entity '%s' is stopping the simulation!\n",
								entities[i]->name);
						stopped = 1;
					}
				}

				cycles++;
			}

			// Occasional synchronization stuff.
			for (i = 0; i < ec; i++) {
				if (entities[i]->occasional() < 0) {
					printf("Entity '%s' is stopping the simulation!\n",
							entities[i]->name);
					stopped = 1;
				}
			}
		}
	}

	// Finalize the simulation.
	for (i = 0; i < ec; i++) {
		entities[i]->fini();
	}

	// Print the ending message.
	printf("Simulation ended at %lld cycles.\n", cycles);

}
