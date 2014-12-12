#!/bin/bash

if [ $# -ne 2 ]; then
  echo "Usage: prj2do.sh <infile.prj> <outfile.do>"
else
  cp $1 $2
  sed -i 's/vhdl rvex/vcom -quiet -93 -work rvex/g' $2
fi

