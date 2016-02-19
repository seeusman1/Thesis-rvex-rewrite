
# This script is tested with Xilinx 14.7. Vivado was not used because the
# tutorial this script is based is using old IP libraries which are no longer
# supported. The following script should set up the Xilinx ISE 14.7 environment
# when sourced.
XILINX_ENV = /opt/applics/bin/xilinx-14.7.sh

.PHONY: help
help:
	@echo ""
	@echo "This script attempts to follow most of the steps in the following tutorial:"
	@echo "http://fpga.org/2013/05/24/yet-another-guide-to-running-linaro-ubuntu-desktop-on-xilinx-zynq-on-the-zedboard/"
	@echo ""
	@echo "Before running, make sure:"
	@echo ""
	@echo " - Xilinx ISE 14.7 + EDK is installed, and the following script will setup"
	@echo "   the environment for it:"
	@echo "   $(XILINX_ENV)"
	@echo "   (if not, modify XILINX_ENV at the top of the makefile)"
	@echo ""
	@echo " - DO NOT source the xilinx environment script yourself, because it will mess"
	@echo "   up a bunch of the other commands. The makefile will source it when necessary."
	@echo ""
	@echo "To run the script, run 'make all -j'."
	@echo ""
	@echo "It's possible that the download links get broken. All these links are in the"
	@echo "'automatic downloads' section of the makefile, just below this help message."
	@echo "Godspeed."
	@echo ""


#-------------------------------------------------------------------------------
# AUTOMATICS DOWNLOADS
#-------------------------------------------------------------------------------

downloads/cf_adv7511_zed_edk_14_4_2013_02_05.tar.gz:
	mkdir -p downloads
	cd downloads && wget https://wiki.analog.com/_media/resources/fpga/xilinx/kc705/cf_adv7511_zed_edk_14_4_2013_02_05.tar.gz

repositories/u-boot-xlnx:
	mkdir -p repositories
	-cd repositories && git clone https://github.com/Xilinx/u-boot-xlnx.git \
	  && git checkout 4cb9c3de73d66372d40d24baf82fa87a702f0c9b \
	  && git apply ../../u-boot.patch


#-------------------------------------------------------------------------------
# Housekeeping
#-------------------------------------------------------------------------------

XPS_WORK = cf_adv7511_zed
U_BOOT = repositories/u-boot-xlnx

TARGETS  = $(XPS_WORK)/implementation/system.bit
TARGETS += $(XPS_WORK)/u-boot.elf

.PHONY: all
all: $(TARGETS)


#-------------------------------------------------------------------------------
# Building the programmable logic hardware
#-------------------------------------------------------------------------------

$(XPS_WORK)/system.xmp: downloads/cf_adv7511_zed_edk_14_4_2013_02_05.tar.gz
	tar xzvf $^

$(XPS_WORK)/implementation/system.bit: $(XPS_WORK)/system.xmp
	echo "run bits" > $(XPS_WORK)/run.tcl
	source $(XILINX_ENV) && cd $(XPS_WORK) && xps -nw -scr run.tcl system.xmp


#-------------------------------------------------------------------------------
# Build u-boot, the Linux boot-loader
#-------------------------------------------------------------------------------

$(XPS_WORK)/u-boot.elf: repositories/u-boot-xlnx
	
