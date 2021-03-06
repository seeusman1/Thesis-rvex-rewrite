
top: help

# User configuration.
../../config.makefile:
	cd ../.. && $(MAKE) config.makefile
-include ../../config.makefile

# Uncomment to use the Xilinx-generated device tree instead of the confirmed
# working no-pl device tree.
#USE_XILINX_DEVTREE=1

# Uncomment to use the out-of-box design u-boot and kernel, which definitely
# works, but you need to manually boot using "run sdboot_linaro". If this is
# is commented, u-boot and the kernel will be compiled locally.
#USE_OOB_KERNEL=1

ifndef DEV
ifdef ZED_SD_DEV
DEV = $(ZED_SD_DEV)
endif
endif

# Include tool names.
include ../../tools.makefile

# Common directories.
DL             = dl
BOOT           = boot

# Temporary file.
TEMP          := temp-$(shell date +"%N")

# Programmable logic Vivado project paths.
PL_PATH        = pl
PL_GEN_TCL     = pl-project-gen.tcl
PL_CFG_TCL     = pl-project-cfg.tcl
PL_SYN_TCL     = pl-project-syn.tcl
PL_GIT_BD      = pl-project.bd
PL_PRJ_BD      = $(PL_PATH)/pl.srcs/sources_1/bd/system/system.bd
PL_XPR         = $(PL_PATH)/pl.xpr
PL_BIT         = $(PL_PATH)/pl.runs/impl_1/system_wrapper.bit
PL_HDF         = $(PL_PATH)/pl.runs/impl_1/system_wrapper.sysdef

# Zedboard pre-built/out-of-the-box design files.
OOB_URL        = https://reference.digilentinc.com/_media/zedboard:zedboard_oob_design.zip
OOB_PATH       = $(DL)/oob
OOB_DEP        = $(OOB_PATH)/.time-downloaded
OOB_UBOOT_ELF  = $(OOB_PATH)/ZedBoard_OOB_Design/boot_image/u-boot.elf
OOB_FSBL_ELF   = $(OOB_PATH)/ZedBoard_OOB_Design/boot_image/zynq_fsbl.elf
OOB_BOOT_BIN   = $(OOB_PATH)/ZedBoard_OOB_Design/sd_image/BOOT.BIN
OOB_ZIMAGE     = $(OOB_PATH)/ZedBoard_OOB_Design/sd_image/zImage

# Device tree stuff.
DTB_XLNX_REPO  = git://github.com/Xilinx/device-tree-xlnx.git
DTB_XLNX_PATH  = $(DL)/device-tree-xlnx
DTB_XLNX_DEP   = $(DTB_XLNX_PATH)/.time-downloaded
DEVTREE_DTS    = $(BOOT)/dts/system.dts

# First stage bootloader (FSBL).
FSBL_PATH      = $(BOOT)/fsbl
FSBL_ELF       = $(FSBL_PATH)/fsbl/executable.elf

# U-boot bootloader.
UBOOT_REPO     = https://github.com/Xilinx/u-boot-xlnx.git
UBOOT_TAG      = xilinx-v14.4
UBOOT_COMMIT   = b7aa48eabf62c25ee78e7660eb658ca35466597f
UBOOT_PATH     = $(DL)/u-boot
UBOOT_DEP      = $(DL)/.u-boot-time-downloaded
UBOOT_PATCH    = u-boot.patch
UBOOT_OUT      = $(UBOOT_PATH)/u-boot
UBOOT_ELF      = $(BOOT)/u-boot.elf

# Linux kernel.
KERNEL_REPO    = https://github.com/analogdevicesinc/linux.git
KERNEL_TAG     = xcomm_zynq_4_0
KERNEL_COMMIT  = 8234393cbdc488574fc48bbba9c063b1646611ec
KERNEL_PATH    = $(DL)/kernel
KERNEL_DEP     = $(DL)/.kernel-time-downloaded
KERNEL_UIMAGE  = $(KERNEL_PATH)/arch/arm/boot/uImage
KERNEL_DTS_PATH= $(KERNEL_PATH)/arch/arm/boot/dts

# Device tree and boot files.
BOOT_IMG       = $(BOOT)/image
DEVTREE        = $(BOOT_IMG)/devicetree_linaro.dtb
BOOT_BIN       = $(BOOT_IMG)/BOOT.BIN
KERNEL_IMAGE   = $(BOOT_IMG)/zImage

# Linaro Linux download.
LINARO_URL     = https://releases.linaro.org/archive/12.09/ubuntu/leb-panda/linaro-precise-ubuntu-desktop-20120923-436.tar.gz
LINARO_PATH    = $(DL)/linaro
LINARO_TGZ     = $(LINARO_PATH)/linaro.tar.gz
LINARO_DEP     = $(LINARO_TGZ)

# Home directory stuff.
HOME_DIR_SRC   = ../../impl ../../utils

#-------------------------------------------------------------------------------
# Housekeeping
#-------------------------------------------------------------------------------

.PHONY: help
help:
	@echo ""
	@echo " This directory/makefile is used to create a bootable SD card for the Zedboard"
	@echo " with Linaro linux running headless, i.e. without PL dependencies. The PL is"
	@echo " configured using a Vivado IP block diagram."
	@echo ""
	@echo " The script requires Vivado and assume version 2015.2. It will automatically"
	@echo " source the environment script when needed; don't do this manually! The location"
	@echo " of the script is configured in config.makefile."
	@echo ""
	@echo " Main targets:"
	@echo ""
	@echo "  configure         : opens the programmable logic block diagram in Vivado, to"
	@echo "                      let you configure the PL peripherals."
	@echo ""
	@echo "  all               : builds all files needed to make the bootable SD card for"
	@echo "                      the Zedboard. This includes the PL bitfile, u-boot and"
	@echo "                      the Linux kernel. Linaro is downloaded pre-built."
	@echo ""
	@echo "  sdcard            : correctly formats an SD card for the Zedboard. This needs"
	@echo "                      root permissions. The target will ask you for the SD card"
	@echo "                      device file unless you specified it in config.makefile,"
	@echo "                      and ALWAYS asks for confirmation."
	@echo ""
	@echo "  ssh               : shortcut to SSH to the board. You will need to install"
	@echo "                      openssh-server with apt-get on the board before this will"
	@echo "                      work."
	@echo ""
	@echo "  clean             : removes all generated files except for the following:"
	@echo "                       - boot/image/devicetree_linaro.dtb"
	@echo "                       - boot/image/zImage"
	@echo "                       - boot/u-boot.elf"
	@echo "                      While these files *can* be generated, you don't really"
	@echo "                      want to do that all the time."
	@echo ""
	@echo "  all-clean         : same as clean, but includes its exceptions."
	@echo ""
	@echo "  dl-clean          : removes all downloaded files."
	@echo ""
	@echo " Subtargets:"
	@echo ""
	@echo "  bitfile           : forcibly regenerates the Zedboard bit file and copies it"
	@echo "                      to system.bit in this directory."
	@echo ""
	@echo "  pl-clean          : cleans/resets the PL Vivado project."
	@echo ""
	@echo "  uboot             : builds the u-boot bootloader."
	@echo ""
	@echo "  uboot-clean       : cleans/resets the u-boot bootloader files."
	@echo ""
	@echo "  uboot-update-patch: regenerates the u-boot patchfile. Before changing u-boot"
	@echo "                      source files and running this command, please run"
	@echo "                      make uboot-clean first."
	@echo ""
	@echo "  kernel            : compiles the Linux kernel for the Zedboard."
	@echo ""
	@echo "  kernel-clean      : cleans/resets the Linux kernel files."
	@echo ""
	@echo "  boot              : builds all files needed for the boot partition of the"
	@echo "                      Zedboard SD card."
	@echo ""

.PHONY: clean
clean: pl-clean uboot-clean kernel-clean
	$(RM) -r temp-*
	$(RM) $(shell $(FIND) boot -type f | $(GREP) -vE "^(boot/u-boot\.elf|boot/image/devicetree_linaro\.dtb|boot/image/zImage)")
	$(RM) -r $(shell $(FIND) boot/* -type d | $(GREP) -vE "^boot/image")
	$(RM) system.bit *.jou *.log

.PHONY: clean
all-clean: clean
	$(RM) -r $(BOOT)

.PHONY: dl-clean
dl-clean:
	$(RM) -rf $(DL)


#-------------------------------------------------------------------------------
# PL (programmable logic) configuration and synthesis
#-------------------------------------------------------------------------------

# Creates the PL project from the tcl script.
$(PL_PATH):
	@if [ ! -f $@ ]; then \
		echo "$(VIVADO) -mode tcl -source $(PL_GEN_TCL)"; \
		$(VIVADO) -mode batch -source $(PL_GEN_TCL); \
	fi

# Copies the block diagram design from the git-ignored Vivado project into this
# directory for versioning.
$(PL_GIT_BD): $(PL_PRJ_BD)
	$(CP) -f $< $@

# Deletes the PL project. The block diagram is first copied from the project to
# its versioned location.
.PHONY: pl-clean
pl-clean:
	@if [ -f $(PL_PRJ_BD) ]; then \
		echo "$(CP) -f $(PL_PRJ_BD) $(PL_GIT_BD)"; \
		$(CP) -f $(PL_PRJ_BD) $(PL_GIT_BD); \
	fi
	$(RM) -r $(PL_PATH)
	$(RM) -f *.jou *.log

# Opens the PL system Vivado project to allow the user to (re)configure the
# available peripherals.
.PHONY: configure
configure: $(PL_PATH)
	cd $(PL_PATH) && $(VIVADO) -mode tcl -source $(realpath $(PL_CFG_TCL)) $(realpath $(PL_XPR))
	$(CP) -f $(PL_PRJ_BD) $(PL_GIT_BD)

# Runs PL system synthesis and implementation.
$(PL_BIT) $(PL_HDF): $(PL_PATH)
	$(CP) -f $(PL_PRJ_BD) $(PL_GIT_BD)
	cd $(PL_PATH) && $(VIVADO) -mode batch -source $(realpath $(PL_SYN_TCL)) $(realpath $(PL_XPR))
	$(CP) $(PL_BIT) system.bit

# Forcibly (re)runs PL system synthesis and implementation.
bitfile: pl-clean $(PL_BIT)


#-------------------------------------------------------------------------------
# Boot partition generation
#-------------------------------------------------------------------------------

boot: $(DEVTREE) $(BOOT_BIN) $(KERNEL_IMAGE)

# Out-of-the-box design - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$(OOB_DEP):
	$(MKDIR) -p $(OOB_PATH)
	$(RM) -rf $(OOB_PATH)/*
	cd $(OOB_PATH) && $(WGET) --no-check-certificate -O oob.zip $(OOB_URL)
	cd $(OOB_PATH) && $(UNZIP) oob.zip
	$(RM) $(OOB_PATH)/oob.zip
	@echo "" > $@

# Device tree - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$(DTB_XLNX_DEP):
	$(MKDIR) -p $(DTB_XLNX_PATH)
	$(GIT) clone $(DTB_XLNX_REPO) $(DTB_XLNX_PATH)
	@echo "" > $@

$(DEVTREE_DTS): $(DTB_XLNX_DEP) $(PL_HDF)
	$(RM) -r $(BOOT)/hsi
	$(RM) -r $(BOOT)/dts
	$(MKDIR) -p $(BOOT)/hsi
	$(CP) $(PL_HDF) $(BOOT)/hsi/system_wrapper.hdf
	@echo "open_hw_design system_wrapper.hdf" > $(BOOT)/hsi/source_hsi.tcl
	@echo "set_repo_path $(realpath $(DTB_XLNX_PATH))" >> $(BOOT)/hsi/source_hsi.tcl
	@echo "create_sw_design device-tree -os device_tree -proc ps7_cortexa9_0" >> $(BOOT)/hsi/source_hsi.tcl
	@echo "generate_target -dir ../dts" >> $(BOOT)/hsi/source_hsi.tcl
	cd $(BOOT)/hsi && $(HSI) -source source_hsi.tcl -mode batch

ifdef USE_XILINX_DEVTREE
$(DEVTREE): $(DEVTREE_DTS)
	$(MKDIR) -p $(BOOT_IMG)
	$(DTC) -I dts -O dtb -o $@ $<
else
ifdef USE_OOB_KERNEL
$(DEVTREE): oob-kernel-nopl.dts
	$(MKDIR) -p $(BOOT_IMG)
	$(DTC) -I dts -O dtb -o $@ $<
else
ifeq ($(wildcard $(DEVTREE)),)
$(DEVTREE): $(KERNEL_DEP)
	$(MKDIR) -p $(BOOT_IMG)
	@echo "/dts-v1/;" > $(KERNEL_DTS_PATH)/zynq-zed-no-pl.dts
	@echo "" >> $(KERNEL_DTS_PATH)/zynq-zed-no-pl.dts
	@echo "/include/ \"zynq-zed.dtsi\"" >> $(KERNEL_DTS_PATH)/zynq-zed-no-pl.dts
	@echo "/ {" >> $(KERNEL_DTS_PATH)/zynq-zed-no-pl.dts
	@echo "	amba {" >> $(KERNEL_DTS_PATH)/zynq-zed-no-pl.dts
	@echo "		leds {" >> $(KERNEL_DTS_PATH)/zynq-zed-no-pl.dts
	@echo "			compatible = \"gpio-leds\";" >> $(KERNEL_DTS_PATH)/zynq-zed-no-pl.dts
	@echo "" >> $(KERNEL_DTS_PATH)/zynq-zed-no-pl.dts
	@echo "			mmc_led {" >> $(KERNEL_DTS_PATH)/zynq-zed-no-pl.dts
	@echo "				label = \"mmc_led\";" >> $(KERNEL_DTS_PATH)/zynq-zed-no-pl.dts
	@echo "				gpios = <0x5 0x7 0x0>;" >> $(KERNEL_DTS_PATH)/zynq-zed-no-pl.dts
	@echo "				linux,default-trigger = \"mmc0\";" >> $(KERNEL_DTS_PATH)/zynq-zed-no-pl.dts
	@echo "			};" >> $(KERNEL_DTS_PATH)/zynq-zed-no-pl.dts
	@echo "		};" >> $(KERNEL_DTS_PATH)/zynq-zed-no-pl.dts
	@echo "	};" >> $(KERNEL_DTS_PATH)/zynq-zed-no-pl.dts
	@echo "};" >> $(KERNEL_DTS_PATH)/zynq-zed-no-pl.dts
	$(DTC) -I dts -O dtb -o $@ $(KERNEL_DTS_PATH)/zynq-zed-no-pl.dts
else
$(DEVTREE):
endif
endif
endif

# FSBL  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

FSBL_PATH      = $(BOOT)/fsbl

$(FSBL_ELF): $(PL_HDF)
	$(RM) -r $(FSBL_PATH)
	$(MKDIR) -p $(FSBL_PATH)
	$(CP) $(PL_HDF) $(FSBL_PATH)/system_wrapper.hdf
	@echo "open_hw_design system_wrapper.hdf" >> $(FSBL_PATH)/hsi.tcl
	@echo "generate_app -hw system_wrapper -os standalone -proc ps7_cortexa9_0 -app zynq_fsbl -compile -sw fsbl -dir fsbl" >> $(FSBL_PATH)/hsi.tcl
	cd $(FSBL_PATH) && $(HSI) -mode batch -source hsi.tcl

# U-boot  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$(UBOOT_DEP):
	$(MKDIR) -p $(UBOOT_PATH)
	$(GIT) clone $(UBOOT_REPO) $(UBOOT_PATH)
	cd $(UBOOT_PATH) && $(GIT) checkout -b $(UBOOT_TAG) $(UBOOT_TAG)
	cd $(UBOOT_PATH) && $(GIT) checkout $(UBOOT_COMMIT)
	@echo "" > $@

.PHONY: uboot-clean
uboot-clean:
	-cd $(UBOOT_PATH) && git clean -fdx && git reset --hard
	-cd $(UBOOT_PATH) && git apply $(realpath .)/$(UBOOT_PATCH)

.PHONY: uboot-update-patch
uboot-update-patch:
	cd $(UBOOT_PATH) && git diff > $(realpath .)/$(UBOOT_PATCH)

.PHONY: uboot
uboot: $(UBOOT_OUT)
$(UBOOT_OUT): $(UBOOT_DEP) $(UBOOT_PATCH)
	cd $(UBOOT_PATH) && git clean -fdx && git reset --hard
	cd $(UBOOT_PATH) && git apply $(realpath .)/$(UBOOT_PATCH)
	$(ARM_CROSS) cd $(UBOOT_PATH) && make zynq_zed_config
	$(ARM_CROSS) cd $(UBOOT_PATH) && make -j 8

ifeq ($(wildcard $(UBOOT_ELF)),)
ifdef USE_OOB_KERNEL
$(UBOOT_ELF): $(OOB_UBOOT_ELF)
	$(MKDIR) -p $(BOOT)
	$(CP) -f $< $@
else
$(UBOOT_ELF): $(UBOOT_OUT)
	$(MKDIR) -p $(BOOT)
	$(CP) -f $< $@
endif
else
$(UBOOT_ELF):
endif

# BOOT.BIN  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$(BOOT_BIN): $(FSBL_ELF) $(PL_BIT) $(UBOOT_ELF)
	$(MKDIR) -p $(BOOT_IMG)
	@echo "the_ROM_image:" > $(BOOT)/output.bif
	@echo "{" >> $(BOOT)/output.bif
	@echo "	[bootloader]$(realpath $(FSBL_ELF))" >> $(BOOT)/output.bif
	@echo "	$(realpath $(PL_BIT))" >> $(BOOT)/output.bif
	@echo "	$(realpath $(UBOOT_ELF))" >> $(BOOT)/output.bif
	@echo "}" >> $(BOOT)/output.bif
	cd $(BOOT) && $(BOOTGEN) -w -image output.bif -o $(shell pwd)/$(BOOT_BIN)

# Linux kernel  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

kernel: $(KERNEL_DEP)
$(KERNEL_DEP):
	$(MKDIR) -p $(KERNEL_PATH)
	$(GIT) clone $(KERNEL_REPO) $(KERNEL_PATH)
	cd $(KERNEL_PATH) && $(GIT) checkout $(KERNEL_COMMIT)
	@echo "" > $@

.PHONY: kernel-clean
kernel-clean:
	-cd $(KERNEL_PATH) && git clean -fdx && git reset --hard

$(KERNEL_UIMAGE): $(KERNEL_DEP) $(UBOOT_OUT)
	-$(RM) $(KERNEL_UIMAGE)
	$(ARM_CROSS) \
		export ARCH=arm && \
		export PATH=$(realpath $(UBOOT_PATH)/tools):$$PATH && \
		cd $(KERNEL_PATH) && \
		$(MAKE) zynq_xcomm_adv7511_defconfig && \
		$(MAKE) -j8 uImage LOADADDR=0x00008000

ifdef USE_OOB_KERNEL
$(KERNEL_IMAGE): $(OOB_DEP)
	$(MKDIR) -p $(BOOT_IMG)
	$(CP) -f $(OOB_ZIMAGE) $(KERNEL_IMAGE)
else
ifeq ($(wildcard $(KERNEL_IMAGE)),)
$(KERNEL_IMAGE): $(KERNEL_UIMAGE)
	$(MKDIR) -p $(BOOT_IMG)
	$(CP) -f $(KERNEL_UIMAGE) $(KERNEL_IMAGE)
else:
$(KERNEL_IMAGE):
endif
endif


#-------------------------------------------------------------------------------
# Linaro stuff
#-------------------------------------------------------------------------------

$(LINARO_TGZ):
	$(MKDIR) -p $(LINARO_PATH)
	$(WGET) --no-check-certificate -O $(LINARO_TGZ) $(LINARO_URL)


#-------------------------------------------------------------------------------
# Zedboard bootable SD card formatting
#-------------------------------------------------------------------------------

.PHONY: all sdcard-deps
all: boot $(LINARO_TGZ)
ifndef DEV
sdcard-deps:
	@echo ""
	@echo " Please run"
	@echo ""
	@echo "   make sdcard-deps"
	@echo ""
	@echo " WITHOUT sudo before running make sdcard."
else
sdcard-deps: boot $(LINARO_TGZ)
endif

.PHONY: sdcard
ifndef DEV
sdcard:
	@echo ""
	@echo " This command images an SD card to work with the zedboard."
	@echo ""
	@echo " Call it like this:"
	@echo ""
	@echo "   make sdcard-deps"
	@echo "   [sudo] make sdcard DEV=/dev/<device-file>"
	@echo ""
	@echo " On my system, <device-file> is mmcblk0, but it might be different for you."
	@echo ""
	@echo " BE EXTREMELY CAREFUL. IF YOU SPECIFY THE WRONG DEVICE FILE, YOU COULD DESTROY"
	@echo " YOUR SYSTEM. ALSO, THE CONTENTS OF THE SD CARD WILL BE DESTROYED."
	@echo ""
	@echo " If you run into problems, filling the MBR and boot partition with zeros before"
	@echo " formatting might help. You can do this by appending NUKE=1 to the make command."
	@echo ""
else
DEVP := $(shell echo $(DEV) | $(SED) -E "s/([0-9])$$/\1p/")
DEVP1 = $(DEVP)1
DEVP2 = $(DEVP)2
sdcard:
	
	# Make sure the user knows what (s)he's doing.
	@echo "ABOUT TO IMAGE $(DEV). IT WILL BE OVERWRITTEN."
	@$(PYTHON) -c "x=raw_input('Type YES if you really want this: '); import sys; sys.exit(0 if x == 'YES' else 1)"
	
	# Unmount partitions, just in case.
	-$(UMOUNT) $(DEVP1)
	-$(UMOUNT) $(DEVP2)
	
ifdef NUKE
	# Nuke any existing master boot record.
	-$(DD) if=/dev/zero of=$(DEV) bs=65536 count=2
endif
	
	# Make master boot record.
	$(RM) -r $(TEMP)
	@echo "# partition table of /correct/table" > $(TEMP)
	@echo "unit: sectors" >> $(TEMP)
	@echo "" >> $(TEMP)
	@echo "/correct/table/backup1 : start=     8192, size=   131072, Id= b" >> $(TEMP)
	@echo "/correct/table/backup2 : start=   147456, size=         , Id=83" >> $(TEMP)
	@echo "/correct/table/backup3 : start=        0, size=        0, Id= 0" >> $(TEMP)
	@echo "/correct/table/backup4 : start=        0, size=        0, Id= 0" >> $(TEMP)
	$(SFDISK) $(DEV) -H128 -S63 -f --no-reread < $(TEMP)
	$(RM) -r $(TEMP)
	
ifdef NUKE
	# Nuke any existing data on the boot partition.
	-$(DD) if=/dev/zero of=$(DEVP1) bs=65536
endif
	
	# Format the boot partition.
	$(MKFS_FAT) -F 32 -s 1 -n boot $(DEVP1)
	
	# Copy the boot files to the boot partition.
	$(MKDIR) -p $(TEMP)
	$(MOUNT) $(DEVP1) $(TEMP)
	$(CP) $(BOOT_IMG)/* $(TEMP)
	$(UMOUNT) $(DEVP1)
	$(RM) -r $(TEMP)
	
	# Format EXT4 Linaro root filesystem.
	$(MKFS_EXT4) -F -L root $(DEVP2)
	
	# Mount the Linaro root filesystem and copy Linaro to it.
	$(MKDIR) -p $(TEMP)
	$(MOUNT) $(DEVP2) $(TEMP)
	$(TAR) xzvf $(LINARO_TGZ) -C $(TEMP) --strip-components=3 binary/boot/filesystem.dir
	
	# Copy the sw and drivers folders to the home directory.
	$(CP) -r $(HOME_DIR_SRC) $(TEMP)/home/linaro
	
	# Remove the message-of-the-day scripts that do update checks, because they
	# are slow as hell when logging in with SSH. Note that SSH is not available
	# by default; you'll have to install it using
	#   sudo apt-get install openssh-server
	# on the board while it is connected to the internet.
	$(RM) $(TEMP)/etc/update-motd.d/90-*
	$(RM) $(TEMP)/etc/update-motd.d/91-*
	$(RM) $(TEMP)/etc/update-motd.d/98-*
	
	# Unmount Linaro root.
	# THIS MAY TAKE A WHILE BECAUSE OF FILESYSTEM CACHING. DON'T CTRL+C IT!
	$(UMOUNT) $(DEVP2)
	$(RM) -r $(TEMP)
	
endif


#-------------------------------------------------------------------------------
# Convenience stuff
#-------------------------------------------------------------------------------

EXP_HEAD  = set timeout 100; match_max 100000
EXP_LOGIN = expect "*continue*"; send -- "yes\r"; expect "*?assword:*"; send -- "linaro\r"
EXP_DATE  = expect "*$$*"; send -- "sudo date -s \"$(shell date)\"\r"
EXP_SU    = expect "*$$*"; send -- "sudo su\r"

.PHONY: ssh
ssh:
ifndef ZED_HOST
	@echo ""
	@echo " This command opens an SSH connection to the zedboard at ZED_HOST. It removes"
	@echo " the host key first to prevent MitM attack warnings from popping up after"
	@echo " re-flashing the board."
	@echo ""
	@echo " Call it like this:"
	@echo ""
	@echo "   make ssh ZED_HOST=<hostname>"
	@echo ""
	@echo " You can also put ZED_HOST in config.makefile if it's always the same."
	@echo ""
else
	-$(SSH_KEYGEN) -R $(ZED_HOST) -f ~/.ssh/known_hosts
	$(EXPECT) -c '$(EXP_HEAD); spawn $(SSH) -X linaro@$(ZED_HOST); $(EXP_LOGIN); $(EXP_DATE); $(EXP_SU); interact'
endif

.PHONY: bridge
bridge:
ifndef ZED_HOST
	@echo ""
	@echo " This command opens a port forwarding SSH connection to the zedboard at"
	@echo " ZED_HOST for port 21079, which allows you to use rvd on your host machine if"
	@echo " rvsrv is running on the board. It removes the host key first to prevent MitM"
	@echo " attack warnings from popping up after re-flashing the board."
	@echo ""
	@echo " Call it like this:"
	@echo ""
	@echo "   make bridge ZED_HOST=<hostname>"
	@echo ""
	@echo " You can also put ZED_HOST in config.makefile if it's always the same."
	@echo ""
else
	-$(SSH_KEYGEN) -R $(ZED_HOST) -f ~/.ssh/known_hosts
	$(EXPECT) -c '$(EXP_HEAD); spawn $(SSH) -N -L 21079:localhost:21079 linaro@$(ZED_HOST); $(EXP_LOGIN); send_user "\n\nPort forwarding now active. Press ctrl+c to exit."; interact'
endif

