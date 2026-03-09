; myisa program to find factorial of a number

; r0 contains the number whose factorial we want
addi r0, zero,
0d7

addi r1, zero,
0d1

;;; LOOP START
; Counter is in r9
cmp r9, r0
; Break out of loop condition
addi r8, pc,
;; This value must be (6+number of lines in LOGIC)
0d-10
beq r8

;; Logic in loop
addi r2, r2,
0d1
mul r1, r2
add r1, zero, lo
;; Logic in loop ends

; Increment loop counter
addi r9, r9,
0d1
; jump back to loop (unconditional)
addi r7, pc,
;; This value must be (7+number of lines in LOGIC)
0d11
b r7
;;; LOOP END

; Store the final answer in mem[0]
sw r1, zero,
0d0
