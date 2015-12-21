#!/bin/sh
rm -f rvex-block-diagram-linked.tex
cp rvex-block-diagram.tex rvex-block-diagram-linked.tex
sed -i -r -e 's/\{rv \(rvex processor\)\}/\{\\hyperlink\{entity:rv\}\{rv \(rvex processor\)\}\}/' rvex-block-diagram-linked.tex
sed -i -r -e 's/\{pls \(pipelanes\)\}/\{\\hyperlink\{entity:pls\}\{pls \(pipelanes\)\}\}/' rvex-block-diagram-linked.tex
sed -i -r -e 's/\{pl \(pipelane\)\}/\{\\hyperlink\{entity:pl\}\{pl \(pipelane\)\}\}/' rvex-block-diagram-linked.tex

for ENTITY in br alu mulu memu brku cxplif fwd dmsw trap limm gpreg cxreg creg gbreg cfg trace imem dmem mem rctrl dbg sim trsink
do
  sed -i -r -e "s/\{$ENTITY\}/\{\\\\hyperlink\{entity:$ENTITY\}\{$ENTITY\}\}/" rvex-block-diagram-linked.tex
done
