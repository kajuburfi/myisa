; myisa program to multiply two 16 bit numbers into a 16 bit memory space. (LOW bits only)

; input(filled in by user)
; <loc>    <value>
; 0000     multiplicand (A)
; 0001     multiplier (B)

; output after running the processor
; <loc>     <value>
; 0003      product - low 16 bits

; loading multiplicand and multiplier
lw r0, zero,
0d0
lw r1, zero,
0d1

; initializing variables
add r2, zero, zero ;product low bits(PL)
addi r4, zero, ;mask value
0d1
addi r5, zero, ;counter for number of masks
0d16

; r7 = r1 & r4 (multiplier & mask)
nand r7, r1, r4
nand r7, r7, r7
cmp r7, zero
addi r9, pc,
0d-5 ; 14 initially
beq r9

;product(low bits) += A. If overflow, then product(high bits)+=1
add r6, r2, zero ;save the old low product
add r2, r2, r0 ;r2 = old PL + A

;;; after_add:
add r0, r0, r0 ; A = A + A
add r4, r4, r4 ; M = M + M(mask)

addi r5, r5,
0d-1
cmp r5, zero
addi r9, pc,
0d13 ; 22 initially
bgt r9

sw r2, zero,
0d3
