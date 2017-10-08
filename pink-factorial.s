################################################################################

.global main

number = 10

################################################################################

.text

################################################################################

main:
    push    {lr}

    ldr     r0, =clear
    bl      do_escape
    ldr     r0, =voffset
    bl      do_escape
    ldr     r0, =hoffset
    bl      do_escape
    ldr     r0, =pink
    bl      do_escape
    ldr     r0, =bold
    bl      do_escape

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
#   r0      some number a
#
# returns:
#   r0      factorial(a)
#
# Calculates a factorial of the given number.

    push    {r1, lr}
    mov     r1, r0
    mov     r0, #1
1:
    tst     r1, r1
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

    ldr     r0, =escape
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

1:
    umull   r3, r4, r0, r1
    mls     r5, r4, r6, r0

    push    {r5}
    add     r2, #1

    subs    r7, #1
    bne     2f

    mov     r5, #-0x10
    push    {r5}
    add     r2, #1
    mov     r7, #3

2:
    movs    r0, r4
    bne     1b

    ldr     r1, =num_buf
1:
    pop     {r0}

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

fact_sign:  .ascii "! = \000"

escape:     .ascii "\033["

cmd_buf:    .fill 4

num_buf:    .fill 128

clear:      .ascii "2J\000"

voffset:    .ascii "12d\000"

hoffset:    .ascii "32G\000"

pink:       .ascii "31m\000"

bold:       .ascii "1m\000"

reset:      .ascii "\033c\000"

################################################################################

# EOF

################################################################################
