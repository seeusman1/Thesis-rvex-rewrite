
# Basic tools.
CP             = cp
RM             = rm -f
MKDIR          = mkdir
TOUCH          = touch
CHMOD          = chmod
CHOWN          = chown
FIND           = find
GIT            = git
WGET           = wget
TAR            = tar
UNZIP          = unzip
SED            = sed
GREP           = grep
PYTHON         = python
EXPECT         = expect
SSH            = ssh
SSH_KEYGEN     = ssh-keygen
DTC            = dtc
DD             = dd
MOUNT          = mount
UMOUNT         = umount
SFDISK         = sfdisk
MKFS_FAT       = mkfs.vfat
MKFS_EXT4      = mkfs.ext4

# Xilinx tools.
WITH_VIVADO    = source $(VIVADO_ENV) &&
VIVADO         = $(WITH_VIVADO) vivado
HSI            = $(WITH_VIVADO) hsi
BOOTGEN        = $(WITH_VIVADO) bootgen
ARM_CROSS      = $(WITH_VIVADO) export CROSS_COMPILE=arm-xilinx-linux-gnueabi- &&

# Modelsim tools.
VSIM           = vsim
VCOM           = vcom
