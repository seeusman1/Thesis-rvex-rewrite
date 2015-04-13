Northwest Logic Delivery for nwl_ip (Version 1.00) Date: 12/03/2010 13:30
===============================================================================

Delivery Notes
-------------

Included:
  Xilinx Virtex 6 x4 64-bit Gen 2 Hard PCIe Core
  Northwest Logic DMA Back-End - Packet DMA for Xilinx Virtex 6 x4 64-bit Gen 2 Hard PCIe Core
  Northwest Logic Expresso Solution Reference Design - Packet DMA
  Northwest Logic PCI Express Bus Functional Model
  Northwest Logic PCI Express Verification Suite



Reference Design
----------------
A full reference design has been provided which implements the following
resources:
  BAR0   - Registers
  BAR1/2 - Map to the same internal SRAM resource
  DMA    - Packet DMA Engines including:
             * Packet Generators to generate packets for C2S Packet DMA
             * Packet Checkers to consume and validate packets for S2C Packet DMA
             * Packet Loopback test mode for re-transmitting received packets
  
The reference design provides a highly useful starting point for customer
designs as it implements a full register, target, and DMA design.

The reference design, including streaming FIFOs, supports System Addresses and
Packet lengths that are multiples of the CORE_DATA_WIDTH in bytes.  Support can
be extended to support System Addresses and Packet Lengths down to byte alignments
by defining PACKET_DMA_BYTE_SUPPORT, however the additional muxing and fanout
that is requried may impact route speed and a faster speed grade may be necessary
to close timing for 250 MHz operation.

Note that the provided reference design Packet DMA test routines use DWORD aligned
Packet Generator/Checker to source/sink data and that these test routines do not
support alignments less than 1 DWORD (4 bytes) even when PACKET_DMA_BYTE_SUPPORT 
is defined.



Coregen
-------
An ISE Coregen project file has been provided to generate the 
Xilinx Virtex 6 x4 64-bit Gen 2 Hard PCIe Core
in the manner expected by the reference design.

Before the reference design simulation or route can be executed, the
Xilinx Virtex 6 x4 64-bit Gen 2 Hard PCIe Core
must be generated.

Note: Xilinx Virtex 6 x4 64-bit Gen 2 Hard PCIe Core
is available is ISE 11.4 or later.

To execute the Coregen project, open a command window in the release
xilinx_coregen directory and type the following:

> coregen -b v6_pcie_v2_1.xco

This will create the required hard core wrapper files and 
simulation model.



Setting up Xilinx Simulation Models
-----------------------------------
Prior to running the provided reference design simulation,
it is necessary to configure your simulator to support the Xilinx 
Transceiver Models.

Instructions for setting up Xilinx models for the most common
simulators are available in the Xilinx Synthesis and
Simulation Design Guide UG626:
http://www.xilinx.com/support/documentation/sw_manuals/xilinx11/sim.pdf

Once your simulator is properly configured, it is necessary to
compile the models using the compxlib utility.

Here is an example command to compile the SmartModels for ModelSim PE 6.6:
compxlib -s mti_pe -p C:/tools/Modeltech_6.6/win32pe -l all -arch all -lib all -w



ModelSim Simulation
-------------------
Two ModelSim simulation scripts have been included to
simulate the provied reference design.  Modify ref_design_ts.v
to change the stimulus of the simulation.

To run the simulation: open ModelSim, change to the ref_design/tb
directory and type one of the following (the latter has support for byte
alignemnts):

> do sim.do
> do sim_byte.do

The ModelSim .do scripts are TCL and are easily ported to other simulators.



Route
-----
An example route project has been provided which builds the reference 
design for the Xilinx ML605 populated with xc6vlx240t-1-ff1156.



Docs
----
User Guides are available in the doc directory



Support
-------
I look forward to supporting you in your use of the provided cores.
Please contact me at

  email: mwagner@nwlogic.com
  phone: 503-533-5800 x307

Mark Wagner
Senior Design Engineer
Northwest Logic, Inc.
1100 NW Compton Dr. Suite 100
Beaverton, OR 97006


File Descriptions
-----------------

  Xilinx Virtex 6 x4 64-bit Gen 2 Hard PCIe Core:
     - xilinx_coregen\v6_pcie_v2_1.xco (top-level)
     - xilinx_coregen\coregen.cgp

  Northwest Logic DMA Back-End - Packet DMA for Xilinx Virtex 6 x4 64-bit Gen 2 Hard PCIe Core:
     - netlist\full\dma_back_end_pkt_bb.v
     - netlist\full\dma_back_end_pkt.ngc (top-level)

  Northwest Logic Expresso Solution Reference Design - Packet DMA:
     - ref_design\ref_inferred_block_ram.v
     - ref_design\register_example.v
     - ref_design\target_example.v
     - ref_design\c2s_adr_pkt.v
     - ref_design\c2s_pkt_streaming_fifo.v
     - ref_design\packet_check.v
     - ref_design\packet_gen.v
     - ref_design\ref_bin_to_gray.v
     - ref_design\ref_dc_fifo.v
     - ref_design\ref_dc_fifo_adv_block_ram.v
     - ref_design\ref_dc_fifo_shallow_ram.v
     - ref_design\ref_gray_sync_bus.v
     - ref_design\ref_gray_to_bin.v
     - ref_design\ref_inferred_shallow_ram.v
     - ref_design\ref_sc_fifo_shallow_ram.v
     - ref_design\ref_tiny_fifo.v
     - ref_design\s2c_adr_pkt.v
     - ref_design\s2c_pkt_streaming_fifo.v
     - ref_design\sdram_dma_ref_design_pkt.v
     - ref_design\xil_pcie_wrapper.v
     - ref_design\sram_dma_ref_design_pkt_xil_axi.v

  Northwest Logic PCI Express Bus Functional Model:
     - models\pcie_model_rp\pcie_model_rp.vp (top-level)

  Northwest Logic PCI Express Verification Suite:
     - sim\report_assertions.v
     - sim\ref_design_ts.v
     - sim\tb_top.v (top-level)
     - sim\master_bfm.v
     - sim\direct_dma_bfm.v
     - sim\pcie_bfm.v

