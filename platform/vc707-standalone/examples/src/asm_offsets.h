/* Copyright 2013 Joost Hoozemans, TU Delft
 *
 *
 *
 */

#ifndef ASM_OFFSETS_H_
#define ASM_OFFSETS_H_

#define TRACEREG_SZ   	0x120					/* includes 20 bytes padding */
#define REGFILE_SIZE 	(4 * 62) +(3* 4) + 8
#define REGSIZE_GR		(4 * 62)


#define PT_R1			0x0
#define PT_R2			0x4
#define PT_R3			0x8
#define PT_R4			0xc
#define PT_R5			0x10
#define PT_R6			0x14
#define PT_R7			0x18
#define PT_R8			0x1c
#define PT_R9			0x20
#define PT_R10			0x24
#define PT_R11			0x28
#define PT_R12			0x2c
#define PT_R13			0x30
#define PT_R14			0x34
#define PT_R15			0x38
#define PT_R16			0x3c
#define PT_R17			0x40
#define PT_R18			0x44
#define PT_R19			0x48
#define PT_R20			0x4c
#define PT_R21			0x50
#define PT_R22			0x54
#define PT_R23			0x58
#define PT_R24			0x5c
#define PT_R25			0x60
#define PT_R26			0x64
#define PT_R27			0x68
#define PT_R28			0x6c
#define PT_R29			0x70
#define PT_R30			0x74
#define PT_R31			0x78
#define PT_R32			0x7c
#define PT_R33			0x80
#define PT_R34			0x84
#define PT_R35			0x88
#define PT_R36			0x8c
#define PT_R37			0x90
#define PT_R38			0x94
#define PT_R39			0x98
#define PT_R40			0x9c
#define PT_R41			0xa0
#define PT_R42			0xa4
#define PT_R43			0xa8
#define PT_R44			0xac
#define PT_R45			0xb0
#define PT_R46			0xb4
#define PT_R47			0xb8
#define PT_R48			0xbc
#define PT_R49			0xc0
#define PT_R50			0xc4
#define PT_R51			0xc8
#define PT_R52			0xcc
#define PT_R53			0xd0
#define PT_R54			0xd4
#define PT_R55			0xd8
#define PT_R56			0xdc
#define PT_R57			0xe0
#define PT_R58			0xe4
#define PT_R59			0xe8
#define PT_R60			0xec
#define PT_R61			0xf0
#define PT_R62			0xf4

#define PT_LR			0xf8
#define PT_PC			0xfc
#define PT_CCR			0x100

#define PT_B0			0x104
#define PT_B1			0x105
#define PT_B2			0x106
#define PT_B3			0x107
#define PT_B4			0x108
#define PT_B5			0x109
#define PT_B6			0x10a
#define PT_B7			0x10b

#define STACK_SCRATCH_AREA (8*4)

#endif /* ASM_OFFSETS_H_ */
