
# Optimization flags.
ifdef DEBUG
    OPTIM_FLAGS = -Og -g
else
    OPTIM_FLAGS = -O3 -flto
endif

# Toolchain.
CC = g++
CFLAGS = $(OPTIM_FLAGS) -fopenmp -Wall -ansi -fms-extensions -std=gnu++11 -pedantic
ENSURE_DIR = mkdir -p

# Modelsim .so file flags. Taken from FLI examples.
MSIM_CFLAGS = $(OPTIM_FLAGS) -Wall -ansi -fms-extensions -std=gnu++11
MSIM_CFLAGS += -pedantic
MSIM_LDFLAGS = $(OPTIM_FLAGS) -shared -Wl,-Bsymbolic -Wl,-export-dynamic
ifeq ($(shell uname -m), x86_64)
    MSIM_CFLAGS += -m64 -fPIC
    MSIM_LDFLAGS += -m64
else
    MSIM_CFLAGS += -m32 -fPIC
    MSIM_LDFLAGS += -m32
endif
MSIM_CFLAGS += -freg-struct-return
MSIM_CFLAGS += -I$$MTI_HOME/include

# Binary output directory.
BINDIR = bin

# Look for source files.
MAGIC = -name "*.cpp" -or -name "*.c" | sed -e "s/\\.c\(pp\)\?$$//g"
MSIM_OBS_ = $(shell find src/modelsim $(MAGIC))
RVSIM_OBS = $(shell find src/rvsim $(MAGIC))
MSIM_OBS  = $(MSIM_OBS_) $(shell find src/rvsim/components/rvex $(MAGIC))
ALL_OBS   = $(MSIM_OBS_) $(RVSIM_OBS)


.PHONY: all msim rvsim
rvsim: $(BINDIR)/rvsim
all: $(BINDIR)/rvsim $(BINDIR)/core.so
msim: $(BINDIR)/core.so

# Dependency generation.
%.d: %.c
	$(CC) $(CFLAGS) -MM $^ > $@

-include $(ALL_OBS:=.d)

# Standalone simulator compilation.
%.o: %.c
	$(CC) $(CFLAGS) -c $^ -o $@

%.o: %.cpp
	$(CC) $(CFLAGS) -c $^ -o $@

$(BINDIR)/rvsim: $(RVSIM_OBS:=.o)
	$(ENSURE_DIR) $(BINDIR)
	$(CC) $(CFLAGS) $^ -o $@

# Modelsim C model compilation.
MTI_INC = $(shell echo $$MTI_HOME/include)

$(MTI_INC):
	@echo -e "\e[1;31mError: you need to source the modelsim environment script before compiling.\e[0m"
	@false

%.mso: %.c $(MTI_INC)
	$(CC) $(MSIM_CFLAGS) -c $< -o $@

%.mso: %.cpp $(MTI_INC) 
	$(CC) $(MSIM_CFLAGS) -c $< -o $@

$(BINDIR)/core.so: $(MTI_INC) $(MSIM_OBS:=.mso)
	$(ENSURE_DIR) $(BINDIR)
	$(CC) $(MSIM_LDFLAGS) -o $@ $(MSIM_OBS:=.mso) -lm -lpthread

# Cleaning.
.PHONY: clean
clean:
	rm -rf $(BINDIR)
	rm -f $(ALL_OBS:=.o) $(ALL_OBS:=.mso) $(ALL_OBS:=.d)

