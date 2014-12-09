# 8 issue vex 1 cluster
CFG: Debug 0
RES: IssueWidth 8
RES: MemLoad 1 
RES: MemStore 1 
RES: MemPft 1 
RES: IssueWidth.0 8
RES: Alu.0 8
RES: Mpy.0 4 
RES: CopySrc.0 2 
RES: CopyDst.0 2 
RES: Memory.0 1 
DEL: AluR.0 0		
DEL: Alu.0 0 		
DEL: CmpBr.0 1 
DEL: CmpGr.0 0 
DEL: Select.0 0 
DEL: Multiply.0 1 
DEL: Load.0 1
DEL: LoadLr.0 2
DEL: Store.0 0
DEL: Pft.0 0 
DEL: CpGrBr.0 1 
DEL: CpBrGr.0 0 
DEL: CpGrLr.0 1 
DEL: CpLrGr.0 0 
DEL: Spill.0 0 
DEL: Restore.0 1 
DEL: RestoreLr.0 2
REG: $r0 63 
REG: $b0 8

# but what does it mean?
