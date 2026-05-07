; myisa program to divide two 16 bit numbers and give quotient and remainder

; input(filled in by user)
; <loc>    <value>
; 0000     dividend (A)
; 0001     divisor (B)

; output after running the processor
; <loc>     <value>
; 0003      quotient
; 0004      remainder

; loading dividend and divisor
lw r0, zero,
0d0
lw r1, zero,
0d1

; if r1 == 0(divisor == 0), then skip to end(because division by zero is undefined)
cmp r1, zero
addi r9, pc,
0d-21
beq r9

;init
add r2, zero, zero
add r3, zero, r0

;loop
cmp r3, r1
addi r9, pc,
0d-9
bgt r9
addi r9, pc,
0d-6
beq r9
addi r9, pc,
0d-9
b r9

;sub
sub r3, r3, r1
addi r2, r2,
0d1
addi r9, pc,
0d13
b r9

;end
sw r2, zero,
0d3
sw r3, zero,
0d4
