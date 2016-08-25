
CC = gcc
CFLAGS = -g

ifndef BIN
BIN = bin
endif

ifndef SRC
SRC = src
endif

.PHONY: all

all: $(BIN)/rvsrv $(BIN)/rvd $(BIN)/rvtrace $(BIN)/runrvex

RVSRV_SRCS  = $(SRC)/rvsrv/*.c
RVSRV_SRCS += $(SRC)/rvsrv/pcie/*.c
RVSRV_SRCS += $(SRC)/rvsrv/mmio/*.c
RVSRV_SRCS += $(SRC)/rvsrv/uart/*.c
RVSRV_SRCS += $(SRC)/common/*.c

$(BIN)/rvsrv: $(RVSRV_SRCS)
	mkdir -p $(BIN)
	$(CC) $(CFLAGS) -Wall -I $(SRC)/common -o $@ $^

RVD_SOURCES  = $(SRC)/rvd/*.c
RVD_SOURCES += $(SRC)/rvd/gdb/*.c
RVD_SOURCES += $(SRC)/rvd/commands/*.c
RVD_SOURCES += $(SRC)/common/*.c

$(BIN)/rvd: $(RVD_SOURCES)
	mkdir -p $(BIN)
	$(CC) $(CFLAGS) -Wall -I $(SRC)/rvd -I $(SRC)/common -o $@ $^

RTRACE_SOURCES  = $(SRC)/rvtrace/*.c
RTRACE_SOURCES += $(SRC)/common/*.c

$(BIN)/rvtrace: $(RTRACE_SOURCES)
	mkdir -p $(BIN)
	$(CC) $(CFLAGS) -Wall -I $(SRC)/common -o $@ $^

$(BIN)/runrvex: runrvex/runrvex.py
	ln -rfs $< $@

