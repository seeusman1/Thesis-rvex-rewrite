-- Asserts that the output from one part of the bitwise op kernel is equal.

wait    400 write *  4  1  exclusive
wait    40  write *  8  1  exclusive
wait    40  write * 12  1  exclusive
wait    40  write * 16  0  exclusive
wait    40  write * 20  0  exclusive
wait    40  write * 24  0  exclusive
read    dmem byte 0 0b000111
