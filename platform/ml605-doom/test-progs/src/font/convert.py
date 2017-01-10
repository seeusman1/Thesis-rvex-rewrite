#!/usr/bin/python

import sys

if len(sys.argv) < 2:
  print('Usage: python convert.py <font.ppm>')
  sys.exit(2)

filename = sys.argv[1]
fontname = ''.join(filename.split('.')[:-1])

with open(filename, 'r') as f:
  ppm = f.readlines()
  
raw = [not l.startswith('255') for l in ppm[4::3]]
width = int(ppm[2].split(' ')[0].strip())
height = int(ppm[2].split(' ')[1].strip())

def getline(x):
  global raw, width, height
  val = 0
  for y in reversed(range(height)):
    if raw[x + y*width]:
      val |= 1
    val <<= 1
  return val

lines = [getline(x) for x in range(width)]


chars = [None]*256
c = 33

started = False
white = 0
for l in lines:
  if started and not l:
    white += 1
    if white > 2:
      started = False
      chars[c] = chars[c][:-2]
      c += 1
  elif l:
    white = 0
    if not started:
      started = True
      chars[c] = []
  if started:
    chars[c].append(l)


# info array: 5 MSB = character width, 11 LSB = index in data array
info = []

# data array: vertical line data for the font, LSB at the top
data = ['0x0000', '0x0000', '0x0000']

for c in range(256):
  if chars[c]:
    info.append('0x%04X' % ((len(chars[c]) << 11) + len(data)))
    for l in chars[c]:
      data.append('0x%04X' % l)
  else:
    info.append('0x1800') # 3 pixels wide, offset 0

def print_array(a, indent):
  ss = ''
  s = indent
  for e in a:
    if len(s) + len(e) > 80:
      ss += s + '\n'
      s = indent
    s += e + ', '
  ss += s
  s = ss[:-2] + '\n'
  return s

c = """#include "gfx.h"

static const unsigned short %s_data[%d] = {
%s};

const font_t %s = {
  %d, // height
  { // info
%s  },
  %s_data
};

""" % (
  fontname,
  len(data),
  print_array(data, '  '),
  fontname,
  height,
  print_array(info, '    '),
  fontname
)

with open('font_' + fontname + '.c', 'w') as f:
  f.write(c)


