################################################################################
#
# libprint.s
#
# Contains procedures to print and parse numbers.
#
################################################################################

################################################################################

# Parse integer. Register r0 is ptr to char array, zero terminated.

parse:
        ptr     .req r0
        char    .req r1
        acc     .req r2
        base    .req r3
        push    {lr}
        eor     acc, acc
        eor     char, char
        mov     base, #10
1:
        ldrb    char, [ptr], #1
        tst     char, char
        beq     2f
        sub     char, char, #0x30
        mla     acc, base, acc, char
        b       1b
2:
        mov     r0, acc
        pop     {pc}

################################################################################

# args:         r0  some number a
# returns:      r0  factorial(a)

# Calculates a factorial of the given number.

fact:   push    {r1, lr}
        mov     r1, r0
        mov     r0, #1
1:      tst     r1, r1
        pople   {r1, pc}
        mul     r0, r1, r0
        sub     r1, #1
        b       1b

################################################################################

# args:         r0 integer to print

# Print unsigned integer in hex.

prntx:  push    {lr}
        mov     r1, #0x10
        bl      prnt
        pop     {pc}

################################################################################

# args:         r0 integer to print

# Print unsigned integer as decimal.

prntd:  push    {lr}
        mov     r1, #10
        bl      prnt
        pop     {pc}

################################################################################

# args:         r0 integer to print
#               r1 radix

# Print unsigned integer in a given radix.

prnt:   number  .req r0
        radix   .req r1
        digitc  .req r2
        digit   .req r3
        temp    .req r7

        push    {r0-r3, r7, lr}
        eor     digitc, digitc

1:      udiv    temp, number, radix
        mls     digit, temp, radix, number
        cmp     digit, #10
        addlt   digit, #0x30
        addge   digit, #0x57
        strb    digit, [sp, #-1]!
        add     digitc, #1
        movs    number, temp
        bne     1b

        mov     r0, #1
        mov     r1, sp
        mov     r7, #4      @ write
        svc     #0

        add     sp, digitc

        pop     {r0-r3, r7, pc}

#num_buf: .space 16

################################################################################

# EoF
