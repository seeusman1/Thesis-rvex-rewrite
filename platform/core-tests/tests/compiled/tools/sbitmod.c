/* Binary file to VHDL package file with word array constant.
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

#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <stdint.h>

/**
 * \name ELF32 file datatypes and structures.
 * @{
 */
typedef uint32_t Elf32_Addr;
typedef uint16_t Elf32_Half;
typedef uint32_t Elf32_Off;
typedef  int32_t Elf32_Sword;
typedef uint32_t Elf32_Word;

#define EI_NIDENT 16

#define SWAP16(val) ((((val) & 0xFF) << 8) | (((val) >> 8) & 0xFF))
#define SWAP32(val) ((SWAP16((val) & 0xFFFF) << 16) | SWAP16(((val) >> 16) & 0xFFFF))

typedef struct {
  unsigned char e_ident[EI_NIDENT]; /* File identification. */
  Elf32_Half  e_type;
  Elf32_Half  e_machine;
  Elf32_Word  e_version;
  Elf32_Addr  e_entry;
  Elf32_Off   e_phoff;
  Elf32_Off   e_shoff;
  Elf32_Word  e_flags;
  Elf32_Half  e_ehsize;
  Elf32_Half  e_phentsize;
  Elf32_Half  e_phnum;
  Elf32_Half  e_shentsize;
  Elf32_Half  e_shnum;
  Elf32_Half  e_shstrndx;
} Elf32_Ehdr;

typedef struct {
  Elf32_Word  sh_name;
  Elf32_Word  sh_type;
  Elf32_Word  sh_flags;
  Elf32_Addr  sh_addr;
  Elf32_Off   sh_offset;
  Elf32_Word  sh_size;
  Elf32_Word  sh_link;
  Elf32_Word  sh_info;
  Elf32_Word  sh_addralign;
  Elf32_Word  sh_entsize;
} Elf32_Shdr;

/** @} */

#define SECT_NAME_SIZE 32

/**
 * Section file offsets.
 */
typedef struct {
  uint32_t headerOffs;
  uint32_t dataOffs;
  uint32_t dataSize;
  unsigned char name[SECT_NAME_SIZE + 1];
} SectInfo;

/**
 * Returns the file offsets for the given section in info.
 */
int getSectInfo(
  int f,                     // File handle.
  int sect,                  // Section to read info of.
  const Elf32_Ehdr *fh,      // ELF file header.
  const SectInfo *strInfo,   // Offsets for the string table, or null if unknown.
  SectInfo *info             // Output.
) {
  
  Elf32_Shdr sh;
  
  // Determine the section header offset.
  info->headerOffs = SWAP32(fh->e_shoff) + sect * SWAP16(fh->e_shentsize);
  
  // Seek to the header offset.
  if (lseek(f, info->headerOffs, SEEK_SET) == (off_t)-1) {
    perror("Failed to seek to section header");
    return -1;
  }
  
  // Read the section header.
  if (read(f, &sh, sizeof(Elf32_Shdr)) < sizeof(Elf32_Shdr)) {
    perror("Failed to read section header");
    return -1;
  }
  
  // Parse the offsets.
  info->dataOffs = SWAP32(sh.sh_offset);
  info->dataSize = SWAP32(sh.sh_size);
  
  // If strInfo is non-null, read the name of the section.
  if (strInfo) {
    uint32_t strOff = strInfo->dataOffs + SWAP32(sh.sh_name);
    
    if (lseek(f, strOff, SEEK_SET) == (off_t)-1) {
      perror("Failed to seek to section name");
      return -1;
    }
    
    if (read(f, info->name, SECT_NAME_SIZE) < SECT_NAME_SIZE) {
      perror("Failed to read section name");
      return -1;
    }
    
    // Make sure the name is null-terminated even if it contains garbage.
    info->name[SECT_NAME_SIZE] = 0;
  } else {
    info->name[0] = 0;
  }
  
  // Success.
  return 0;
}

/**
 * Runs the program.
 */
int main(int argc, char **argv) {
  
  const char *filename;
  int bunSize;
  int f;
  Elf32_Ehdr fh;
  SectInfo stringTable;
  int sect;
  
  // Check args.
  if (argc != 3) {
    fprintf(stderr, "Usage: %s <input.elf> <bundle size>\n", argv[0]);
    fprintf(stderr, "\n");
    fprintf(stderr, "Modifies the an r-VEX generic binary .elf file such that it can be run by xSTsim. The\n");
    fprintf(stderr, "stop bits are modified such that each executed bundle stops with a stop bit (i.e., if\n");
    fprintf(stderr, "xSTsim is to simulate in 2-way mode, a stop bit should be present for every odd syllable),\n");
    fprintf(stderr, "and LIMMH targets are modified accordingly.\n");
    fprintf(stderr, "\n");
    fprintf(stderr, "The stop bit is assumed to be bit index 1. A LIMMH instruction is assumed to be\n");
    fprintf(stderr, "0x8------- where - is don't care, with the target lane specified in bit 27..25. The input\n");
    fprintf(stderr, "LIMMH target is expected to be with respect to 32-byte (8 syllable) boundaries.\n");
    return EXIT_FAILURE;
  }
  filename = argv[1];
  if (!strcmp(argv[2], "2")) {
    bunSize = 2;
  } else if (!strcmp(argv[2], "4")) {
    bunSize = 4;
  } else if (!strcmp(argv[2], "8")) {
    bunSize = 8;
  } else {
    fprintf(stderr, "Invalid bundle size specified, must be 2, 4 or 8.\n");
    return EXIT_FAILURE;
  }
  
  // Open the file.
  f = open(filename, O_RDWR);
  if (f < 0) {
    perror("Failed to open file for writing");
    return EXIT_FAILURE;
  }
  
  // Read the file header.
  if (read(f, &fh, sizeof(Elf32_Ehdr)) < sizeof(Elf32_Ehdr)) {
    perror("Failed to read ELF file header");
    return EXIT_FAILURE;
  }
  
  // Read the string table section offsets.
  if (!fh.e_shstrndx) {
    fprintf(stderr, "Error: ELF file does not contain string table section.");
    return EXIT_FAILURE;
  }
  if (getSectInfo(f, SWAP16(fh.e_shstrndx), &fh, 0, &stringTable)) {
    return EXIT_FAILURE;
  }
  
  // Loop over all sections.
  for (sect = 1; sect < SWAP16(fh.e_shnum); sect++) {
    SectInfo sectInfo;
    if (getSectInfo(f, sect, &fh, &stringTable, &sectInfo)) {
      return EXIT_FAILURE;
    }
    
    // See if this is the .text section.
    if (!strcmp(sectInfo.name, ".text")) {
      
      int i;
      
      // Seek to the start of the section.
      if (lseek(f, sectInfo.dataOffs, SEEK_SET) == (off_t)-1) {
        perror("Failed to seek to .text section contents");
        return -1;
      }
      
      // Modify the stop bits.
      for (i = 0; i < sectInfo.dataSize / 4; i++) {
        
        uint32_t syllable;
        
        // Read the syllable.
        if (read(f, &syllable, 4) < 4) {
          perror("Failed to read syllable");
          return EXIT_FAILURE;
        }
        syllable = SWAP32(syllable);
        
        // Update the stop bit.
        if ((i % bunSize) == (bunSize - 1)) {
          syllable |= 0x00000002; // Set stop bit.
        } else {
          syllable &= ~0x00000002; // Clear stop bit.
        }
        
        // Update LIMMH target.
        if ((syllable & 0xF0000000) == 0x80000000) {
          if (bunSize == 2) syllable &= ~0x0C000000;
          if (bunSize == 4) syllable &= ~0x08000000;
        }
        
        // Seek back to overwrite the syllable.
        if (lseek(f, -4, SEEK_CUR) == (off_t)-1) {
          perror("Failed to seek within .text section contents");
          return -1;
        }
        
        // Write the new syllable.
        syllable = SWAP32(syllable);
        if (write(f, &syllable, 4) < 4) {
          perror("Failed to write syllable");
          return EXIT_FAILURE;
        }
        
      }
      
      // Close the file.
      close(f);
      
      return EXIT_SUCCESS;
    }
    
  }
  
  // Couldn't find .text section.
  fprintf(stderr, "Error: ELF file does not contain .text section.");
  
  // Close the file.
  close(f);
  
  return EXIT_FAILURE;
  
};