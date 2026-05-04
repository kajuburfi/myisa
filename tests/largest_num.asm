; myisa program to find the largest number from an "array"

; Input: to be filled by user
; In memory,
; <loc>             <value>
; 0000         <Number of ele in array>
; 0001         <first ele>
; 0002         <second ele>
; 0003         <third ele>
;  and so on

; Output:
; In memory,
; <loc>               <value>
; <num ele> + 1       max ele

; r0 contains the number of elements in "array"
lw r0, zero,
0d0

; r1 is the maximum element in array
lw r1, zero,
0d1

;;; LOOP START
; Counter is in r9 - zero initially
cmp r9, r0
; Break out of loop condition
addi r8, pc,
;; This value must be (8+number of lines in LOGIC)
0d-16
bgt r8

;; --- Logic in loop ---
; The current value is stored in r2
lw r2, r9,
0d2
; compare the max and the current value
cmp r1, r2

; IF r1 > r2, do nothing(branch to r7), else replace r1, r2
addi r7, pc,
0d-5
bgt r7

sub r1, r1, r1 ;make r1 zero
add r1, zero, r2 ; put r2 in r1
;; --- Logic in loop ends ---

; Increment loop counter
addi r9, r9,
0d1
; jump back to loop (unconditional)
addi r7, pc,
;; The following value must be
;; - In c_impl (7+number of lines in LOGIC)
;; - In single_cycle (6+nunber of lines in LOGIC)
0d14
b r7
;;; LOOP END

sw r1, r0,
0d1

