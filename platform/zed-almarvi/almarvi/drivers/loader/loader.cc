/*
 * This example loader controls accelerators according to the ALMARVI interface rev1 
 */

#include <iostream>
#include <fstream>
#include <vector>
using namespace std;

#define IN (0)
#define OUT (1)

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/mman.h>
#include <fcntl.h>

#define CTRL_SIZE       (2048)
#define MEMORY_SIZE     (512*1024)

#define CTRL_CMD        (128)
#define CTRL_CMD_RUN    (2)
#define CTRL_CMD_HALT   (1)
#define CTRL_STATUS     (0)
#define CTRL_PC         (1)
#define CTRL_CYCLECOUNT (2)
#define CTRL_LOCKCOUNT  (3)

#define CTRL_INFO_DEVCLASS       (192)
#define CTRL_INFO_DEVID          (193)
#define CTRL_INFO_INTERFACE_TYPE (194)
#define CTRL_INFO_DMEM_SIZE      (195)
#define CTRL_INFO_IMEM_SIZE      (196)
#define CTRL_INFO_PMEM_SIZE      (197)

void usage(void)
{
	cout << "*argv[0] -m <MEMORY_ADDR> -c <CONTROL_ADDR> -p <fn> (-o <fn> -s <dump_start> -e <dump_end>)\n";
	cout << "    -m <MEMORY_ADDR>  Accelerator memory base address\n";
	cout << "    -c <CONTROL_ADDR> Control interface base address\n";
	cout << "    -p <filename>     Input instruction memory image\n";
	cout << "    -o <filename>     Output data memory dump file\n";
	cout << "    -s <dump_start>   Dump start address (relative to MEMORY_ADDR)\n";
	cout << "    -e <dump_size>    Dump size in words\n";
	return;
}

vector<void*> mapped_ptrs;
vector<unsigned> mapped_sizes;

void* map_phys_addr(int fd, int phys_addr, int size) {
	/* mmap the device into memory */
	unsigned page_size=sysconf(_SC_PAGESIZE);

	unsigned page_addr = (phys_addr & (~(page_size-1)));
	unsigned page_offset = phys_addr - page_addr;

	int mmap_size = ((size - page_offset) / page_size) * page_size;
	while(mmap_size < (size-page_offset))
		mmap_size += page_size;
	//printf("phys addr: %08x, size: %d, page addr: %08x, page size: %d\n", phys_addr, size, page_addr, mmap_size);
	void* ptr = mmap(NULL, mmap_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, page_addr);

	mapped_ptrs.push_back(ptr);
	mapped_sizes.push_back(mmap_size);

	return (char*)ptr+page_offset;
}

void unmap_phys_addrs() {
	for(int i=0; i<mapped_ptrs.size(); ++i) {
		munmap(mapped_ptrs[i], mapped_sizes[i]);
	}
}


int main(int argc, char *argv[])
{
	int c;
	int mem_fd;
	int direction=IN;
	unsigned mem_addr = 0;
	char* imem_img_fn = NULL;
	char* dump_fn = NULL;
	int dump_start = -1;
	int dump_size = -1;
	int value = 0;
	
	unsigned page_addr, page_offset;
	void *ptr;

	/* Parse command line arguements */
	while((c = getopt(argc, argv, "m:c:p:o:s:e:")) != -1) {
		switch(c) {
		case 'm':
			mem_addr=strtoul(optarg,NULL,0);
			break;
		case 'p':
			imem_img_fn=optarg;
			break;
		case 'o':
			dump_fn=optarg;
			break;
		case 's':
			dump_start=strtoul(optarg,NULL,0);
			break;
		case 'e':
			dump_size=strtoul(optarg,NULL,0);
			break;
		default:
			cout << "invalid option: " << ((char)c) << endl;
			usage();
			return -1;
		}
		
	}

	if (mem_addr == 0) {
		cout << "Memory address is required.\n";
		usage();
		return -1;
	}

	if (imem_img_fn == NULL) {
		cout << "Imem filename is required.\n";
		usage();
		return -1;
	}

	vector<unsigned> imem_img;
	ifstream imem_img_file(imem_img_fn);
	unsigned word;
	while(imem_img_file >> word) {
		imem_img.push_back(word);
	}
	imem_img_file.close();

	cout << "Base address:\t" << hex << mem_addr << endl;

	/* Open /dev/mem file */
	mem_fd = open ("/dev/mem", O_RDWR);
	if (mem_fd < 1) {
		perror(argv[0]);
		return -1;
	}

	//TODO: At first map just fixed-size CTRL section, then poll memory size, then map full-size memory
	//      Currently memory size is fixed.
	volatile unsigned* mem_ptr = (unsigned*)map_phys_addr(mem_fd, mem_addr, MEMORY_SIZE);

	// Reset accelerator
	mem_ptr[CTRL_CMD] = CTRL_CMD_HALT;

	// Read info registers
	cout << "Device class:\t" << hex << mem_ptr[CTRL_INFO_DEVCLASS] << endl;
	cout << "Device ID:\t" << hex << mem_ptr[CTRL_INFO_DEVID] << endl;

	int ctrl_size = 1024;
	int dmem_size = mem_ptr[CTRL_INFO_DMEM_SIZE];
	int imem_size = mem_ptr[CTRL_INFO_IMEM_SIZE];
	int pmem_size = mem_ptr[CTRL_INFO_PMEM_SIZE];
	cout << "DMEM Size:\t" << dec << dmem_size << endl;
	cout << "IMEM Size:\t" << imem_size << endl;
	cout << "PMEM Size:\t" << pmem_size << endl;

	int section_size = max( max(dmem_size, imem_size), pmem_size);
	int section_size_w = section_size/4; // byte offset -> word offset
	int imem_offset = section_size_w;
	int dmem_offset = section_size_w*2;
	int pmem_offset = section_size_w*3;

	// Flush DMEM&PMEM, initialize IMEM
	// TODO: add option to initialize dmem&pmem from file 
	for(int i=0; i<pmem_size/4; ++i) {
		mem_ptr[pmem_offset+i] = 0;
	}

	for(int i=0; i<dmem_size/4; ++i) {
		mem_ptr[dmem_offset+i] = 0;
	}

	for(int i=0; i<imem_img.size(); ++i) {
		mem_ptr[imem_offset+i] = imem_img[i];
	}

	// Lift softreset
	mem_ptr[CTRL_CMD] = CTRL_CMD_RUN;

	// Uncomment for rough latency count for single memory reads:
 	/*int pc1 = mem_ptr[CTRL_CYCLECOUNT];
	int pc2 = mem_ptr[CTRL_CYCLECOUNT];
	int pc3 = mem_ptr[CTRL_CYCLECOUNT];
	int pc4 = mem_ptr[CTRL_CYCLECOUNT];
	int pc5 = mem_ptr[CTRL_CYCLECOUNT];

	printf("CC: %d\n", pc1);
	printf("CC: %d\n", pc2);
	printf("CC: %d\n", pc3);
	printf("CC: %d\n", pc4);
	printf("CC: %d\n", pc5);*/

	// Wait until program signals completion
	while(!mem_ptr[pmem_offset+1]);

	cout << "Execution complete!" << endl;
	
	cout << "Cycle count:\t" << dec << mem_ptr[CTRL_CYCLECOUNT] << endl;
	cout << "Lock count:\t" << dec << mem_ptr[CTRL_LOCKCOUNT] << endl;

	if(dump_fn) {
		cout << "Dumping data memory to " << dump_fn << endl;

		ofstream dump_file(dump_fn);
	
		for(int i=0; i<dump_size; ++i) {
			dump_file << mem_ptr[dmem_offset+i+dump_start] << endl;
		}
	}

	unmap_phys_addrs();
	return 0;
}

