################################################################################

.global main

number = 10

################################################################################

.macro esc command
        ldr     r0, =\command
        bl      do_escape
.endm

################################################################################

.text

################################################################################

main:   push    {lr}
        esc     clear
        esc     voffset
        esc     hoffset
        esc     pink
        esc     bold
        mov     r0, #number
        bl      print_int
        ldr     r0, =fact_sign
        bl      printf
        mov     r0, #number
        bl      factorial
        bl      print_int
        bl      getchar
        ldr     r0, =reset
        bl      printf
        pop     {pc}

################################################################################

factorial:

# args:
#   r0      some sumber a
#
# returns:
#   r0      factorial(a)
#
# Calculates a factorial of the given number.

        push    {r1, lr}
        mov     r1, r0
        mov     r0, #1
1:      tst     r1, r1
        pople   {r1, pc}
        mul     r0, r1, r0
        sub     r1, #1
        b       1b

################################################################################

do_escape:

# args:
#   r0      address of escape sequence
#
# Printing escape-sequence.

        push    {r0, r1, lr}
        ldr     r1, [r0]
        ldr     r0, =cmd_buf
        str     r1, [r0]
        ldr     r0, =escape_seq
        bl      printf
        pop     {r0, r1, pc}

################################################################################

print_int:

# args:
#   r0  - integer to print
#
# Printing unsigned integer with space as thousands separator.

        push    {r0-r7, lr}
        movw    r1, #0x999A
        movt    r1, #0x1999
        mov     r6, #0xA
        mov     r7, #3
        eor     r2, r2
1:      umull   r3, r4, r0, r1
        mls     r5, r4, r6, r0
        push    {r5}
        add     r2, #1
        subs    r7, #1
        bne     2f
        mov     r5, #-0x10
        push    {r5}
        add     r2, #1
        mov     r7, #3
2:      movs    r0, r4
        bne     1b
        ldr     r1, =num_buf
1:      pop     {r0}
        add     r0, #0x30
        strb    r0, [r1], #1
        subs    r2, #1
        bne     1b
        eor     r0, r0
        strb    r0, [r1]
        ldr     r0, =num_buf
        bl      printf
        pop     {r0-r7, pc}

################################################################################

.data

################################################################################

fact_sign:  .asciz "! = "

escape_seq: .ascii "\033["

cmd_buf:    .space 4

num_buf:    .space 128

clear:      .asciz "2J"

voffset:    .asciz "12d"

hoffset:    .asciz "32G"

pink:       .asciz "31m"

bold:       .asciz "1m"

reset:      .asciz "\033c"

################################################################################

# EOF

################################################################################
