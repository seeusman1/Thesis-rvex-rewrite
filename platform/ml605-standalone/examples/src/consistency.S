
  .section .text
  .global consistency_check
  .proc
consistency_check::
  add $r0.10 = $r0.0, 0x31415926
  add $r0.11 = $r0.0, 0x53589793
  add $r0.12 = $r0.0, 0x23846264
  add $r0.13 = $r0.0, 0x33832795
;;
  add $r0.14 = $r0.0, 0x02884197
  add $r0.15 = $r0.0, 0x16939937
  add $r0.16 = $r0.0, 0x51058209
  add $r0.17 = $r0.0, 0x74944592
;;
  stw 0x3FFFFFFC[$r0.0] = $r0.10
;;
  ldw $r0.20 = 0x3FFFFFFC[$r0.0]
;;
consistency_check_loop:
  stw 0x3FFFFFFC[$r0.0] = $r0.11
;;
  ldw $r0.21 = 0x3FFFFFFC[$r0.0]
  cmpne $b0.0 = $r0.10, $r0.20
;;
  br $b0.0, consistency_error
  stw 0x3FFFFFFC[$r0.0] = $r0.12
;;
  ldw $r0.22 = 0x3FFFFFFC[$r0.0]
  cmpne $b0.0 = $r0.11, $r0.21
;;
  br $b0.0, consistency_error
  stw 0x3FFFFFFC[$r0.0] = $r0.13
;;
  ldw $r0.23 = 0x3FFFFFFC[$r0.0]
  cmpne $b0.0 = $r0.12, $r0.22
;;
  br $b0.0, consistency_error
  stw 0x3FFFFFFC[$r0.0] = $r0.14
;;
  ldw $r0.24 = 0x3FFFFFFC[$r0.0]
  cmpne $b0.0 = $r0.13, $r0.23
;;
  br $b0.0, consistency_error
  stw 0x3FFFFFFC[$r0.0] = $r0.15
;;
  ldw $r0.25 = 0x3FFFFFFC[$r0.0]
  cmpne $b0.0 = $r0.14, $r0.24
;;
  br $b0.0, consistency_error
  stw 0x3FFFFFFC[$r0.0] = $r0.16
;;
  ldw $r0.26 = 0x3FFFFFFC[$r0.0]
  cmpne $b0.0 = $r0.15, $r0.25
;;
  br $b0.0, consistency_error
  stw 0x3FFFFFFC[$r0.0] = $r0.17
;;
  ldw $r0.27 = 0x3FFFFFFC[$r0.0]
  cmpne $b0.0 = $r0.16, $r0.26
;;
  br $b0.0, consistency_error
  stw 0x3FFFFFFC[$r0.0] = $r0.10
;;
  ldw $r0.20 = 0x3FFFFFFC[$r0.0]
  cmpne $b0.0 = $r0.17, $r0.27
;;
  brf $b0.0, consistency_check_loop
;;
consistency_error:
  return $r0.1 = $r0.1, (0x0), $l0.0
;;
  .endp
