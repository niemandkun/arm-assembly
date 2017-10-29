.global _start

.include "libprint.s"

.text

_start:

        ldr     r0, [sp]
        cmp     r0, #2
        bne     exit

        ldr     r0, [sp, #8]
        bl      readfile

        ldr     r0, =filebuf
        bl      strlen

        bl      prntd

        mov     r2, r0
        ldr     r1, =filebuf
        mov     r0, #1
        mov     r7, #4
        svc     #0

exit:
        eor     r0, r0
        mov     r7, #1
        svc     #0

# args: r0 - ptr to file path

readfile:
        push    {r1, lr}
        eor     r1, r1
        mov     r7, #5
        svc     #0
        tst     r0, r0
        ble     1f
        ldr     r1, =filebuf
        ldr     r2, =buflen
        mov     r7, #3
        svc     #0
1:
        pop     {r1, pc}

findstr:
        # r1 - sequence ptr
        # r2 - source ptr
        # strings are zero-terminated
        #
        # returns ptr to substring in source
        # or -1 if source does not contain sequence
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

streq:
        # r1 - ptr to first string
        # r2 - ptr to second string
        # r3 - length
        # returns 1 if strings are equal, 0 otherwise
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

strend:
        # r0 - ptr to zero-terminated string
        # returns address of terminal zero
        push    {r1}
1:
        ldrb    r1, [r0]
        tst     r1, r1
        addne   r0, #1
        bne     1b
        pop     {r1}
        mov     pc, lr

strlen:
        # r0 - ptr to zero-terminated string
        push    {r1,lr}
        mov     r1, r0
        bl      strend
        sub     r0, r0, r1
        pop     {r1,pc}

.bss

buflen = 1000000
filebuf: .space buflen
linebuf: .space buflen
printbuf: .space buflen
