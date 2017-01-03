#ifndef __SIMRVEX_FRAMEBUFFER_H
#define __SIMRVEX_FRAMEBUFFER_H

#define FB_ALIGNMENT          4
#define FB_MAGIC_REG          0x20000000
#define FB_COMMAND_REG        (FB_MAGIC_REG + FB_ALIGNMENT)
#define FB_WIDTH_REG          (FB_MAGIC_REG + 2 * FB_ALIGNMENT)
#define FB_HEIGHT_REG         (FB_MAGIC_REG + 3 * FB_ALIGNMENT)
#define FB_DEPTH_REG          (FB_MAGIC_REG + 4 * FB_ALIGNMENT)
#define FB_FREEZE_REG         (FB_MAGIC_REG + 5 * FB_ALIGNMENT)
#define FB_ADDRESS         0x20100000

#endif
