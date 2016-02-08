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

#ifndef RVSIM_COMPONENTS_CORE_CORE_H
#define RVSIM_COMPONENTS_CORE_CORE_H

#include <inttypes.h>
#include "../rvex/GenericsException.h"

/**
 * Maximum supported core sizes.
 */
#define CORE_MAX_CONTEXTS     8
#define CORE_MAX_LANES        16
#define CORE_MAX_LANE_GROUPS  8

/**
 * Size of the simulation output string buffers.
 */
#define SIM_STR_BUF_LEN 256

/**
 * Defines whether the two-cycle latency of the general purpose register file
 * is modelled. NOTE: this is NOT modelled correctly when clkEn is not always
 * high, as the register logic is only updated when clkEn is active.
 */
#define SIM_GPREG_2CYCLE_LATENCY 1

/**
 * Whether the forwarding logic cache should be used or not. This is only
 * supported when there is only one stage which is being forwarded to.
 */
#define SIM_CACHE_FORWARDING ((S_RD+L_RD == S_FW) && (S_SRD == S_SFW))

/**
 * Number of cycles during which requestReconfig is high and all relevant
 * blockReconfig signals are low before a new runtime configuration is
 * committed.
 */
#define SIM_RECONFIG_COMMIT_LATENCY 2


//==============================================================================
// Generated stuff and basic types.
//==============================================================================
namespace Core {

/**
 * Include generated stuff.
 */
#include "../rvex/Generated.h.inc"

/**
 * VHDL typedefs which are not known by the configuration scripts.
 */
typedef bitvec4_t mask_t;
typedef bitvec32_t syllable_t;
typedef char *charPtr_t;

} /* namespace Core */

//==============================================================================
// Core toplevel interface structures.
//==============================================================================
namespace Core {

/**
 * All rvex core generics.
 */
typedef struct coreInterfaceGenerics_t {

	cfgVect_t  CFG;
    natural_t  CORE_ID;
    bitvec56_t PLATFORM_TAG;

} coreInterfaceGenerics_t;

/**
 * All rvex core input signals.
 */
typedef struct coreInterfaceIn_t {

	// System control.
	bit_t      reset;
	bit_t      clkEn;

	// Run control interface.
	bit_t      rctrl2rv_irq[CORE_MAX_CONTEXTS];
	address_t  rctrl2rv_irqID[CORE_MAX_CONTEXTS];
	bit_t      rctrl2rv_run[CORE_MAX_CONTEXTS];
	bit_t      rctrl2rv_reset[CORE_MAX_CONTEXTS];
    address_t  rctrl2rv_resetVect[CORE_MAX_CONTEXTS];

    // Common memory interface.
    bit_t      mem2rv_blockReconfig[CORE_MAX_LANE_GROUPS];
    bit_t      mem2rv_stallIn[CORE_MAX_LANE_GROUPS];
    cacheStatus_t mem2rv_cacheStatus[CORE_MAX_LANE_GROUPS];

    // Instruction memory interface.
    syllable_t imem2rv_instr[CORE_MAX_LANES];
    bitvec32_t imem2rv_affinity;
    bit_t      imem2rv_busFault[CORE_MAX_LANE_GROUPS];

    // Data memory interface.
    data_t     dmem2rv_readData[CORE_MAX_LANE_GROUPS];
    bit_t      dmem2rv_ifaceFault[CORE_MAX_LANE_GROUPS];
    bit_t      dmem2rv_busFault[CORE_MAX_LANE_GROUPS];

    // Control/debug bus interface.
    address_t  dbg2rv_addr;
    bit_t      dbg2rv_readEnable;
    bit_t      dbg2rv_writeEnable;
    mask_t     dbg2rv_writeMask;
    data_t     dbg2rv_writeData;

    // Trace interface.
    bit_t      trsink2rv_busy;

} coreInterfaceIn_t;

/**
 * All rvex core output signals.
 */
typedef struct coreInterfaceOut_t {

	// System control.
	bit_t      resetOut;

	// VHDL simulation debug information.
	charPtr_t  rv2sim[2*CORE_MAX_LANES + CORE_MAX_LANE_GROUPS + CORE_MAX_CONTEXTS];

	// Run control interface.
	bit_t      rv2rctrl_irqAck[CORE_MAX_CONTEXTS];
	bit_t      rv2rctrl_idle[CORE_MAX_CONTEXTS];
	bit_t      rv2rctrl_done[CORE_MAX_CONTEXTS];

	// Common memory interface.
	bit_t      rv2mem_decouple[CORE_MAX_LANE_GROUPS];
	bit_t      rv2mem_stallOut[CORE_MAX_LANE_GROUPS]; // Combinatorial!

	// Instruction memory interface.
	address_t  rv2imem_PCs[CORE_MAX_LANE_GROUPS];
	bit_t      rv2imem_fetch[CORE_MAX_LANE_GROUPS];
	bit_t      rv2imem_cancel[CORE_MAX_LANE_GROUPS];

	// Data memory interface.
	address_t  rv2dmem_addr[CORE_MAX_LANE_GROUPS];
	bit_t      rv2dmem_readEnable[CORE_MAX_LANE_GROUPS];
	data_t     rv2dmem_writeData[CORE_MAX_LANE_GROUPS];
	mask_t     rv2dmem_writeMask[CORE_MAX_LANE_GROUPS];
	bit_t      rv2dmem_writeEnable[CORE_MAX_LANE_GROUPS];

	// Control/debug bus interface.
	data_t     rv2dbg_readData;

	// Trace interface.
	bit_t      rv2trsink_push;
	byte_t     rv2trsink_data;
	bit_t      rv2trsink_end;

} coreInterfaceOut_t;

} /* namespace Core */

//==============================================================================
// Register and forwarding logic class.
//==============================================================================
namespace Core {

/**
 * List of all the normal registers in the rvex.
 */
typedef enum registerId_t {

	RVREG_GP0  =  0, RVREG_GP1  =  1, RVREG_GP2  =  2, RVREG_GP3  =  3,
	RVREG_GP4  =  4, RVREG_GP5  =  5, RVREG_GP6  =  6, RVREG_GP7  =  7,
	RVREG_GP8  =  8, RVREG_GP9  =  9, RVREG_GP10 = 10, RVREG_GP11 = 11,
	RVREG_GP12 = 12, RVREG_GP13 = 13, RVREG_GP14 = 14, RVREG_GP15 = 15,

    RVREG_GP16 = 16, RVREG_GP17 = 17, RVREG_GP18 = 18, RVREG_GP19 = 19,
    RVREG_GP20 = 20, RVREG_GP21 = 21, RVREG_GP22 = 22, RVREG_GP23 = 23,
    RVREG_GP24 = 24, RVREG_GP25 = 25, RVREG_GP26 = 26, RVREG_GP27 = 27,
    RVREG_GP28 = 28, RVREG_GP29 = 29, RVREG_GP30 = 30, RVREG_GP31 = 31,

    RVREG_GP32 = 32, RVREG_GP33 = 33, RVREG_GP34 = 34, RVREG_GP35 = 35,
    RVREG_GP36 = 36, RVREG_GP37 = 37, RVREG_GP38 = 38, RVREG_GP39 = 39,
    RVREG_GP40 = 40, RVREG_GP41 = 41, RVREG_GP42 = 42, RVREG_GP43 = 43,
    RVREG_GP44 = 44, RVREG_GP45 = 45, RVREG_GP46 = 46, RVREG_GP47 = 47,

    RVREG_GP48 = 48, RVREG_GP49 = 49, RVREG_GP50 = 50, RVREG_GP51 = 51,
    RVREG_GP52 = 52, RVREG_GP53 = 53, RVREG_GP54 = 54, RVREG_GP55 = 55,
    RVREG_GP56 = 56, RVREG_GP57 = 57, RVREG_GP58 = 58, RVREG_GP59 = 59,
    RVREG_GP60 = 60, RVREG_GP61 = 61, RVREG_GP62 = 62, RVREG_GP63 = 63,

    RVREG_BR0  = 64, RVREG_BR1  = 65, RVREG_BR2  = 66, RVREG_BR3  = 67,
    RVREG_BR4  = 68, RVREG_BR5  = 69, RVREG_BR6  = 70, RVREG_BR7  = 71,

    RVREG_LINK = 72,

    RVREG_COUNT = 73

} registerId_t;

/**
 * Stores a single stage's worth of forwarding data.
 */
typedef struct fwdState_t {

	/**
	 * Register state.
	 */
	uint32_t r[RVREG_COUNT];

	/**
	 * Valid bits.
	 */
	uint64_t v[2];

} regFile_t;

/**
 * State of the general purpose register file and gp/br/link forwarding for a
 * context.
 */
class RegistersAndForwarding {
private:

	/**
	 * Pointer to the control register interface for this context.
	 */
	CtrlRegInterfacePerCtxt_t *cregIface = 0;

	/**
	 * Pointer to the generic configuration vector.
	 */
	const cfgVect_t *CFG = 0;

	/**
	 * General purpose register file without forwarding, read values.
	 */
	uint32_t gpreg[64];

#if SIM_GPREG_2CYCLE_LATENCY
	/**
	 * The general purpose register file has a cycle delay on the FPGA. We need
	 * to account for that. When a write to the register file goes through, it
	 * is put in here, then in the next call to afterRead() or afterReadStall(),
	 * it is actually committed.
	 */
	uint32_t gpregBuf[64];
	uint64_t gpregBufValid = 0;
	void updateGpRegDelay();
#endif

	/**
	 * Forwarded data. This is the set of registers which is normally read
	 * from by the core, unless a register is marked as invalid. When a
	 * register is submitted to the forwarding logic, it is placed both in here
	 * as well as in stages. When a register is committed completely, it is
	 * written to gpreg or the appropriate context control registers. When a
	 * stage is invalidated, those registers written by that stage are also
	 * invalidated in fwdCache. When an invalid register is read from fwdCache,
	 * the stages table is walked in order to find the present apparent state of
	 * the register. When this is found, it is also written back into the cache.
	 *
	 * This is only used when there is only one forwarding output, i.e.
	 * S_RD+L_RD == S_FW and S_SRD == S_SFW. If the former is not true, all
	 * reads are processed as a cache miss.
	 */
	fwdState_t cache;

	/**
	 * Commit information for each stage.
	 */
	fwdState_t stages[S_LAST_POW2];

	/**
	 * Stage offset. This is added to a stage before indexing stages (modulo
	 * S_LAST_POW2). offset decrements every cycle, so each index in stages
	 * maps to a single instruction in the pipelane.
	 */
	int offset = 0;

public:

	/**
	 * Creates/destroys a new forwarding controller.
	 * NOTE: NONE OF THE FUCNTIONS IN THIS CLASS ARE ALLOWED TO USE DYNAMIC
	 * MEMORY ALLOCATION, AS THE MODELSIM INTERFACE REQUIRES THE USAGE OF
	 * SPECIALIZED, GARBAGE COLLECTED MEMORY ALLOCATION FUNCTIONS. THIS ALSO
	 * MEANS THAT THE DESTRUCTOR IS NOT NECESSARILY CALLED, AND MUST THUS BE
	 * NO-OP.
	 */
	RegistersAndForwarding() { };
	virtual ~RegistersAndForwarding() { };
	void init(CtrlRegInterfacePerCtxt_t *cregIface, const cfgVect_t *CFG);

	/**
	 * Resets the forwarding logic. Must be called in every clock cycle where
	 * reset is asserted, instead of afterRead(), afterReadStalled() and
	 * afterWrite().
	 */
	void reset();

	/**
	 * Prepares the debug bus read value for the general purpose registers. This
	 * just copies the specified register into debugBusRegBuffer. This is needed
	 * to properly model the latency of the general purpose register file RAM
	 * blocks, as the control registers are simulated after the pipeline, which
	 * is the next cycle as far as this class is concerned.
	 */
	void prepDbgBusGetGpReg(registerId_t reg);
	uint32_t debugBusGpRegBuffer = 0;

	/**
	 * Returns the value of a register, taking forwarding etc. into account.
	 * This also handles the reg63isLink generic and makes sure REG_GP0 always
	 * returns 0.
	 */
	uint32_t getReg(int stage, registerId_t reg);

	/**
	 * Must be called in every unstalled clock cycle after all reads.
	 */
	void afterRead();

	/**
	 * Must be called in every stalled clock cycle after all reads.
	 */
	void afterReadStalled();

	/**
	 * Supplies a new register value to the forwarding logic.
	 */
	void fwdReg(int stage, registerId_t reg, uint32_t value);

	/**
	 * Invalidates a pipeline stage, removing all values which it supplied to
	 * the forwarding system.
	 */
	void invalidate(int stage);

	/**
	 * Must be called in every unstalled clock cycle after all reads and fwdReg
	 * calls.
	 */
	void afterFwdAndInval();

	/**
	 * Commits a register to the register file. This may be called even if
	 * fwdReg has already been called.
	 */
	void commitReg(registerId_t reg, uint32_t value);

};

} /* namespace Core */

//==============================================================================
// Core state structures.
//==============================================================================
namespace Core {

/**
 * State of execution of a single syllable. The items in this structure
 * correspond to the "s" record in core_pipelane.vhd for as far as the signals
 * are necessary. Refer to the documentation there for their purpose.
 */
typedef struct sylState_t {

    uint32_t syllable;
	uint32_t PC;
    unsigned int valid : 1;
	unsigned int limmValid : 1;
	unsigned int brkValid : 1;
    unsigned int memRequested : 1;
    unsigned int memError : 1;
    unsigned int gpRegWriteRequested : 1;
    unsigned int linkRegWriteRequested : 1;
    unsigned int invalidDueToStop : 1;
    unsigned int idle : 1;
    uint8_t brRegWriteRequested;

    // Datapath signals.
    struct {
        uint8_t src1;
		uint8_t src2;
        uint8_t srcBr;
        uint8_t readBr;
        uint32_t read1lo;
        uint32_t read2lo;
        uint32_t readLink;
        uint32_t imm;
        uint8_t useImm;
		uint32_t op1;
		uint32_t op2;
		uint32_t op3;
        uint8_t opBr;
        uint32_t resALU;
        uint32_t resAdd;
        uint32_t resMul;
        uint32_t resMem;
        uint8_t dest;
        uint32_t res;
        uint8_t resValid;
        uint8_t resLinkValid;
        uint8_t destBr;
        uint8_t resBr;
        uint8_t resBrValid;
    } dp;

    // Branch/next PC related signals.
    struct {
        uint32_t branchOffset;
        trapInfo_t trapInfo;
        uint32_t trapPoint;
        uint32_t trapHandler;
        unsigned int trapPending : 1;
        unsigned int RFI : 1;
        unsigned int isBranch : 1;
        unsigned int isBranching : 1;
        char br2sim[SIM_STR_BUF_LEN];
    } br;

    // Trap-related signals.
    struct {
        trapInfo_t trap;
        trapInfo_t debugTrap;
        uint32_t trapHandler;
    } tr;

    // Trace-related signals.
    struct {
        uint32_t mem_address;
        uint32_t mem_writeData;
        cacheStatus_t cache_status;
        uint32_t instr_syllable;
        trapInfo_t trap_info;
        uint32_t trap_point;
        uint8_t mem_writeMask;
        unsigned int stop : 1;
        unsigned int mem_enable : 1;
        unsigned int instr_enable : 1;
    } trace;

} sylState_t;

/**
 * Pipelane state.
 */
typedef struct laneState_t {

	/**
	 * Instruction/pipeline state for each instruction in the pipeline of this
	 * lane, offset by soffs.
	 */
	sylState_t sbuf[S_LAST_POW2];

	/**
	 * Stage offset. This is added to a stage before indexing s (modulo
	 * S_LAST_POW2). offset decrements every non-stalled cycle, so each index in
	 * stages maps to a single instruction in the pipelane.
	 */
	int soffs = 0;

	/**
	 * Instruction/pipeline state for each instruction in the pipeline, indexed
	 * by stage.
	 */
	sylState_t *s[S_LAST + 1];

	/**
	 * Pipeline capabilities.
	 */
	unsigned int HAS_MUL  : 1;
	unsigned int HAS_MEM  : 1;
	unsigned int HAS_BRK  : 1;
	unsigned int HAS_BR   : 1;
	unsigned int HAS_STOP : 1;

	/**
	 * Instruction buffer.
	 */
	uint32_t insnBuf;

} laneState_t;

/**
 * Branch unit state and outputs.
 */
typedef struct branchState_t {

	// PC addition value for PC+1, based on stop bits and/or the number of
	// active lanes.
	uint32_t bundleSize;

	// Outputs. These correspond to the output signals in core_br.vhd, where
	// applicable.
    uint32_t br2cxplif_PC;
    unsigned int br2cxplif_branch : 1;
    unsigned int br2cxplif_imemFetch : 1;
    unsigned int br2cxplif_limmValid : 1;
    unsigned int br2cxplif_valid : 1;
    unsigned int br2cxplif_brkValid : 1;
    unsigned int br2cxplif_imemCancel : 1;
    unsigned int br2cxplif_invalUntilBR : 1;

} branchState_t;

/**
 * State information per context.
 */
typedef struct contextState_t {

	/**
	 * Runtime configuration signals.
	 */
	struct {

		/**
		 * Pointer into the laneState_t array, mapping to the first lane mapped
		 * to this context if laneCount is nonzero.
		 */
		laneState_t *firstLane;

		/**
		 * Index of the first lane.
		 */
		uint8_t firstLaneIdx;

		/**
		 * Number of lanes allocated to this context.
		 */
		uint8_t laneCount;

		/**
		 * First lane group for this context. Undefined if laneCount is 0.
		 */
		uint8_t firstGroup;

		/**
		 * Last lane group for this context. Undefined if laneCount is 0.
		 */
		uint8_t lastGroup;

		/**
		 * Whether a reconfiguration is requested which affects this context.
		 */
		uint8_t requestReconfig;

	} rcfg;

	/**
	 * State of the active branch unit in this context.
	 */
	branchState_t branch;

	/**
	 * Control register file interface (per-context signals).
	 */
	CtrlRegInterfacePerCtxt_t cregIface;

	/**
	 * State of the context control registers.
	 */
	contextRegState_t cxregState;

	/**
	 * Register files and forwarding logic.
	 */
	RegistersAndForwarding regFwd;

} contextState_t;

/**
 * Reconfiguration control unit state.
 */
typedef struct reconfigCtrlState_t {

	/**
	 * Status signals to the control registers.
	 */
    uint32_t currentCfg;
    unsigned int error : 1;
    unsigned int requesterID : 4;

    /**
     * Marks whether the new configuration is valid or erroneous. Undefined when
     * busy is zero.
     */
    unsigned int newCfgValid : 1;

    /**
     * Number of busy cycles remaining.
     */
    uint8_t busy;

    /**
     * New configuration word. Undefined when busy is zero.
     */
    uint32_t newCfg;

    /**
     * Each bit represents whether a context is affected by the ongoing
     * reconfiguration. Undefined when busy is zero.
     */
    uint8_t affectedContexts;

} reconfigCtrlState_t;

/**
 * Overall state.
 */
typedef struct coreState_t {

	/**
	 * State of all the lanes.
	 */
	laneState_t lane[CORE_MAX_LANES];

	/**
	 * State of all the contexts.
	 */
	contextState_t cx[CORE_MAX_CONTEXTS];

	/**
	 * Syscon signals which are used often.
	 */
	uint8_t reset;
	uint8_t clkEn;
	uint8_t cxStall;

	/**
	 * Reconfiguration unit state.
	 */
	reconfigCtrlState_t rcfgState;

	/**
	 * Control register file interface (global signals).
	 */
	CtrlRegInterface_t cregIface;

	/**
	 * State of the global control registers.
	 */
	globalRegState_t gbregState;

} coreState_t;

} /* namespace Core */

//==============================================================================
// Core simulator class.
//==============================================================================
namespace Core {

/**
 * Typedef for a printf-like function pointer, used for the debug function.
 */
typedef void (*printfFuncPtr_t)(const char *format, ...);

/**
 * Main simulator class.
 */
class Core {
private:

	/**
	 * Core output signals.
	 */
	coreInterfaceOut_t out;

	/**
	 * Internal state of the core.
	 */
	coreState_t st;

	/**
	 * Shorthandes for the number of lanes, lane groups and contexts in the
	 * current configuration.
	 */
	const int NUM_LANES;
	const int NUM_GROUPS;
	const int NUM_CONTEXTS;

public:

	/**
	 * Debugging printf function to use. This is just the usual printf for the
	 * standalone simulator, but is overridden to mti_PrintFormatted within a
	 * modelsim environment.
	 */
	const printfFuncPtr_t printf;

	/**
	 * Core generics.
	 */
	const coreInterfaceGenerics_t generics;

	/**
	 * Core input signals.
	 */
	coreInterfaceIn_t in;

	/**
	 * Creates/destroys a new core with the specified generic configuration.
	 * NOTE: NONE OF THE FUCNTIONS IN THIS CLASS ARE ALLOWED TO USE DYNAMIC
	 * MEMORY ALLOCATION, AS THE MODELSIM INTERFACE REQUIRES THE USAGE OF
	 * SPECIALIZED, GARBAGE COLLECTED MEMORY ALLOCATION FUNCTIONS. THIS ALSO
	 * MEANS THAT THE DESTRUCTOR IS NOT NECESSARILY CALLED, AND MUST THUS BE
	 * NO-OP.
	 */
	Core(const coreInterfaceGenerics_t *generics, printfFuncPtr_t printf);
	virtual ~Core() { };

	/**
	 * Generates the stall output signal, which is combinatorial based on the
	 * stall input and the debug bus. Returns the output signal structure.
	 */
	const coreInterfaceOut_t *stallOut(void) throw(GenericsException);

	// TODO/FIXME: combinatorially deactivate memory read/write enable output if
	// a memory trap is incoming.

	/**
	 * Simulates a clock cycle and returns the output signal structure. Note
	 * that comb() must also be called every cycle.
	 */
	const coreInterfaceOut_t *clock(void) throw(GenericsException);

	/**
	 * Returns the output signal structure.
	 */
	const coreInterfaceOut_t *getOut() const;

private:

	//--------------------------------------------------------------------------
	// Contexts.
	//--------------------------------------------------------------------------

	/**
	 * Simulates one processing cycle for the given context. Should only be
	 * called when reset and stall are low.
	 */
	void simulateContext(int ctxt, contextState_t *cst);


	//--------------------------------------------------------------------------
	// Reconfiguration.
	//--------------------------------------------------------------------------

	/**
	 * Simulates the reconfiguration controller.
	 */
	void simulateReconfigurationCtrl();

	/**
	 * Commits a new configuration and cleans up after the reconfiguration
	 * controller. st.cx[...].rcfg is completely written and validated. The
	 * given configuration is assumed to be a valid configuration word.
	 */
	void commitConfiguration(uint32_t cfg);


	//--------------------------------------------------------------------------
	// Control registers.
	//--------------------------------------------------------------------------

	/**
	 * Simulates the control registers.
	 */
	void simulateControlRegs() throw(GenericsException);

	/**
	 * Simulates the control register logic. This function is generated.
	 */
	void simulateControlRegLogic();

};

} /* namespace Core */

#endif
