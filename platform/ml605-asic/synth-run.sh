#!/bin/bash

# Sanity check!
if [ ! -d "vhdl" ]; then
  # Control will enter here if $DIRECTORY exists.
  echo "Please use 'make synth-<app>' to synthesize!"
  exit 1
fi
if [ ! -d "arch" ]; then
  # Control will enter here if $DIRECTORY exists.
  echo "Please use 'make synth-<app>' to synthesize!"
  exit 1
fi

# Exit/don't archive if make fails.
set -e

# Use make to synthesize the design.
make routed.bit timing.twr -j2 2>&1 | tee xilinx.log

# Archive the platform.
../../../versions/tools/archive_platform_complete.py arch

