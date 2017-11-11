##############################################################################
#
# libprint.s
#
# Contains procedures to print and parse numbers.
#
##############################################################################

.global parseint
.global prntx
.global prntxbuf
.global prntd
.global prntdbuf
.global prnt
.global prntbuf
.global prnt1

##############################################################################

# Print string using syscall.

.macro prnts str_ptr str_len
        mov     r0, #1
        ldr     r1, =\str_ptr
        ldr     r2, =\str_len
        mov     r7, #4
        svc     #0
.endm

##############################################################################

# Parse positive integer. Register r0 is ptr to char array, zero terminated.
# Returns -1 if error.

parseint:
        ptr     .req r0
        char    .req r1
        acc     .req r2
        base    .req r3
        push    {r1-r3, lr}
        eor     acc, acc
        eor     char, char
        mov     base, #10
1:
        ldrb    char, [ptr], #1
        tst     char, char
        beq     2f
        subs    char, char, #0x30
        blt     3f
        cmp     char, #9
        bgt     3f
        mla     acc, base, acc, char
        b       1b
2:
        mov     r0, acc
        pop     {r1-r3, pc}
3:
        mov     r0, #-1
        pop     {r1-r3, pc}

##########################V####################################################

# args:         r0 integer to print

# Print unsigned integer in hex.

prntx:  push    {r1,lr}
        mov     r1, #0x10
        bl      prnt
        pop     {r1,pc}

##############################################################################

# args:         r0 integer to print
#               r1 buffer address

# Print unsigned integer in hex into buffer.

prntxbuf:
        push    {r1-r3,lr}
        mov     r3, #8
        mov     r2, r1
        mov     r1, #0x10
        bl      prntbuf
        pop     {r1-r3,pc}

##############################################################################

# args:         r0 integer to print

# Print unsigned integer as decimal.

prntd:  push    {r1,lr}
        mov     r1, #10
        bl      prnt
        pop     {r1,pc}

##############################################################################

# args:         r0 integer to print
#               r1 buffer address

# Print unsigned integer in decimanl into buffer.

prntdbuf:
        push    {r1-r3,lr}
        mov     r3, #2
        mov     r2, r1
        mov     r1, #0x0A
        bl      prntbuf
        pop     {r1-r3,pc}

##############################################################################

# args:         r0 integer to print
#               r1 radix

# Print unsigned integer in a given radix.

prnt:   number  .req r0
        radix   .req r1
        digitc  .req r2
        digit   .req r3
        temp    .req r7

        push    {r0-r3, r7, lr}

        cmp     r1, #1
        beq     2f

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
        b       3f
2:
        bl      prnt1
3:
        pop     {r0-r3, r7, pc}

##############################################################################

# args:         r0 integer to print
#               r1 radix
#               r2 buffer
#               r3 width (for leading zeros)

# Convert unsigned integer in a given radix and write result into buffer.

prntbuf:
        push    {r1-r7, lr}

        mov     r4, r2
        mov     r6, r3
        eor     r5, r5

        tst     r1, r1
        ble     3f

        eor     digitc, digitc
1:
        udiv    temp, number, radix
        mls     digit, temp, radix, number
        cmp     digit, #10
        addlt   digit, #0x30
        addge   digit, #0x57
        strb    digit, [sp, #-1]!
        add     digitc, #1
        movs    number, temp
        bne     1b

        mov     r5, digitc
        mov     temp, r6
        sub     r6, r6, r5
        cmp     r5, temp
        movlt   r5, temp
        mov     temp, #0x30
4:
        tst     r6, r6
        ble     2f
        strb    temp, [r4], #1
        sub     r6, #1
        b       4b

2:
        tst     digitc, digitc
        beq     3f
        ldrb    digit, [sp], #1
        strb    digit, [r4], #1
        sub     digitc, #1
        b       2b
3:
        mov     r0, r5
        pop     {r1-r7, pc}

##############################################################################

# args:         r0 integer to print

# Print unsigned integer in a radix one.

prnt1:
        len     .req r2
        counter .req r3
        dig     .req r4

        push    {r0-r4, lr}
        mov     len, r0
        tst     len, len
        addeq   len, #1
        moveq   dig, #0x30
        movne   dig, #0x31
        mov     counter, len
1:
        strb    dig, [sp, #-1]!
        subs    counter, #1
        bgt     1b

        mov     r0, #1
        mov     r1, sp
        mov     r7, #4
        svc     #0

        add     sp, len

        pop     {r0-r4, pc}

##############################################################################

# EoF
