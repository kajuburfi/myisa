; This file goes through all commands impl.
addi r0, zero,
0d5
addi r1, zero,
0d10
add r2, r1, r0
addi r3, r1,
0d-3
sub r4, r1, r3
nand r5, r4, r0
nandi r6, r5,
0d2
mul r0, r3
mul r1, r2
mul r2, r2
div r2, r0
div r2, r3
cmp r3, r3
cmp r2, r1
addi r7, zero,
0xFFE6
; b r7
nop
nop
cmp r6, r6
addi r7, pc,
0d2
; beq r7
nop
nop
addi r7, pc,
0d3
; bgt r7
nop
nop
nop
nop
addi r7, zero,
0x0000
sw r0, r7,
0d0
sw r1, r7,
0d1
sw r2, r7,
0d2
sw r3, r7,
0d3
sw r4, r7,
0d4
sw r5, r7,
0d5
sw r6, r7,
0d6
sw r7, r7,
0d7
