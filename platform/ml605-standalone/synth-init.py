#!/usr/bin/python3

import xml.etree.ElementTree as etree
import os
import sys

# Check command line.
if len(sys.argv) != 2:
  print('Usage: synth-init.py <infile.xise>')
  print()
  print('Will generate:')
  print('  archive-manifest')
  print('  constraints.ucf')
  print('  project.prj')
  exit(1)

# Determine the path to the original Xilinx project.
prjdir = os.path.dirname(sys.argv[1])

# Parse xise XML file.
root = etree.parse(sys.argv[1]).getroot()

with open('archive-manifest', 'w') as manifest:
  with open('constraints.ucf', 'w') as ucf:
    with open('project.prj', 'w') as project:
      
      # Generate fixed manifest stuff.
      manifest.write("""
[name]
ml605-standalone

[ptag]
ptag.vhd

[logs]
xilinx.log
timing.twr 

[bitfile]
routed.bit

[sources]
../opts-xst.cfg -> opts-xst.cfg
../opts-map.cfg -> opts-map.cfg
../opts-par.cfg -> opts-par.cfg
constraints.ucf -> constraints.ucf
project.prj -> project.prj
ptag.vhd -> vhdl/ptag.vhd
""")
      
      # Append the synthesis makefile to the manifest.
      manifest.write('%s/../../share/synthesis.makefile -> Makefile\n' % (prjdir + os.sep))
      
      # Append ptag.vhd to the project file.
      project.write('vhdl work "vhdl%sptag.vhd"\n' % os.sep)
      
      # Append all the xise files to the project file and manifest.
      for i in root.iter('{http://www.xilinx.com/XMLSchema}file'):
        if '{http://www.xilinx.com/XMLSchema}name' not in i.attrib:
          continue
        filename = prjdir + os.sep + i.attrib['{http://www.xilinx.com/XMLSchema}name']
        if '{http://www.xilinx.com/XMLSchema}type' not in i.attrib:
          continue
        impl = False
        for j in i.iter('{http://www.xilinx.com/XMLSchema}association'):
          if '{http://www.xilinx.com/XMLSchema}name' not in j.attrib:
            continue
          if j.attrib['{http://www.xilinx.com/XMLSchema}name'] == 'Implementation':
            impl = True
            break
        
        # Handle VHDL files.
        if i.attrib['{http://www.xilinx.com/XMLSchema}type'] == 'FILE_VHDL':
          lib = "work"
          for j in i.iter('{http://www.xilinx.com/XMLSchema}library'):
            if '{http://www.xilinx.com/XMLSchema}name' not in j.attrib:
              continue
            lib = j.attrib['{http://www.xilinx.com/XMLSchema}name']
            break
          name = str(i.attrib['{http://www.xilinx.com/XMLSchema}name'])
          
          # Ignore ptag-zero.vhd.
          if 'ptag-zero.vhd' not in name:
            
            # Generate a unique local filename.
            newfilename = 'vhdl' + os.sep + lib + '-' + name.replace(os.sep, '-')
            
            # Append to manifest.
            manifest.write('%s -> %s\n' % (filename, newfilename))
            
            # Append to the project file.
            project.write('vhdl %s "%s"\n' % (lib, newfilename))
        
        # Handle UCF files.
        if i.attrib['{http://www.xilinx.com/XMLSchema}type'] == 'FILE_UCF':
          
          # Append to the UCF file.
          ucf.write('\n')
          ucf.write('# ==============================================================================\n')
          ucf.write('# %s\n' % filename)
          ucf.write('# ==============================================================================\n')
          ucf.write('\n')
          with open(filename, "r") as inucf:
            ucf.write(inucf.read())
        


