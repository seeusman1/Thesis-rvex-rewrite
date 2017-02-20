-- Asserts compf-kernel output for r1 = r2

wait    400 write *  4  1  exclusive
wait    40  write *  8  1  exclusive
wait    40  write * 12  0  exclusive
read    dmem byte 0 0b011
