; myisa program to compute fibonacci numbers

; r0 contains the max value we want to go till 
addi r0, zero,
0d15

; r1 and r2 will be repeatedly added together to get the new values of fibonacci
addi r1, zero,
0d1
add r2, zero, r1

; Store the first and second values in memory
sw r1, r9,
0d0
sw r2, r9,
0d1

;;; LOOP START
; Counter is in r9
cmp r9, r0
; Break out of loop condition
addi r8, pc,
;; This value must be (6+number of lines in LOGIC)
0d-13
bgt r8

;; Logic in loop
; Make the third value as sum of r1 and r2
add r3, r1, r2
; Store it in r9th place, with inc of 2(because of first two values)
sw r3, r9,
0d2
; Update r1 and r2
addi r1, r2,
0d0
addi r2, r3,
0d0
;; Logic in loop ends

; Increment loop counter
addi r9, r9,
0d1
; jump back to loop (unconditional)
addi r7, pc,
;; This value must be (7+number of lines in LOGIC)
0d14
b r7
;;; LOOP END

;;; Below is an example of a basic `for` loop
; cmp r1, r0
; addi r9, pc,
; 0d-6
; bgt r9
; addi r1, r1,
; 0d1
; addi r8, pc,
; 0d7
; b r8
