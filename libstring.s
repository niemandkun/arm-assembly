#############################################################################
#
# string.s
#
# Contains procedures for strings processing.
#
#############################################################################

##############################################################################

# Print zero terminated string
#
# Args:
#   r0 - ptr to zero-terminated string
#
# Returns nothing.

prntz:
        push    {r0-r2,r7,lr}
        mov     r1, r0
        bl      strlen
        mov     r2, r0
        mov     r0, #1
        mov     r7, #4
        svc     #0
        pop     {r0-r2,r7,pc}

##############################################################################

# Find substring inside other string.
#
# Args:
#   r1 - sequence ptr
#   r2 - source ptr
#   strings are zero-terminated
#
# Returns ptr to substring in source or -1 if source
# does not contain sequence

findstr:
        push    {r1-r4,lr}

        mov     r0, r1
        bl      strlen
        mov     r3, r0
        # r1 = sequence ptr
        # r3 = sequence length

        mov     r0, r2
        bl      strlen
        mov     r4, r0
        # r2 = source ptr
        # r4 = source length

        cmp     r3, r4
        bgt     1f

        add     r4, r2, r4
        sub     r4, r4, r3
        # r4 = address of the last substing in the source
        # that may be equal to the sequence

3:
        bl      streq
        tst     r0, r0
        movne   r0, r2
        bne     2f
        add     r2, #1
        cmp     r2, r4
        ble     3b
1:
        mvn     r0, #1
2:
        pop     {r1-r4,pc}

##############################################################################

# Check strings for equality.
#
# Args:
#   r1 - ptr to first string
#   r2 - ptr to second string
#   r3 - length
#
# Returns 1 if strings are equal, 0 otherwise.

streq:
        push    {r4,r5}
        eor     r0, r0
1:
        ldrb    r4, [r1, r0]
        ldrb    r5, [r2, r0]
        cmp     r4, r5
        eorne   r0, r0
        bne     2f
        add     r0, #1
        cmp     r0, r3
        bne     1b
        mov     r0, #1
2:
        pop     {r4,r5}
        mov     pc, lr

##############################################################################

# Find end of string.
#
# Args:
#   r0 - ptr to zero-terminated string
#
# Returns address of terminal zero

strend:
        push    {r1}
1:
        ldrb    r1, [r0]
        tst     r1, r1
        addne   r0, #1
        bne     1b
        pop     {r1}
        mov     pc, lr

##############################################################################

# Find length of string.
#
# Args:
#   r0 - ptr to zero-terminated string
#
# Returns number of characters before terminating zero.

strlen:
        push    {r1,lr}
        mov     r1, r0
        bl      strend
        sub     r0, r0, r1
        pop     {r1,pc}

##############################################################################

# Copy string.
#
# Args:
#   r0 - ptr to source, zero-terminated
#   r1 - ptr to destination
#
# Returns number of characters was copied.

strcpy:
        push    {r2,r3}
        eor     r2, r2
1:
        ldrb    r3, [r0, r2]
        strb    r3, [r1, r2]
        tst     r3, r3
        beq     2f
        add     r2, #1
        b       1b
2:
        mov     r0, r2
        pop     {r2,r3}
        mov     pc, lr

##############################################################################

# EoF
