.global _start

.include "libprint.s"

###############################################################################

.text

###############################################################################

_start:

        ldr     r0, [sp]
        cmp     r0, #3
        bne     usage_error

        ldr     r0, [sp, #8]
        ldr     r1, [sp, #12]
        bl      readfile

        tst     r0, r0
        ble     io_error

        mov     r4, r0
        ldr     r3, =filebuf
        add     r4, r4, r3

        ldr     r2, =linebuf

        # r1 = ptr to target sequence
        # r2 = ptr to linebuf
        # r3 = ptr to file start
        # r4 = ptr to file end

1:
        cmp     r3, r4
        beq     print_matches_count

        mov     r0, r3
        bl      readline
        mov     r3, r0

        bl      findstr
        tst     r0, r0
        blt     1b

        bl      printfound

        ldr     r7, =matches
        ldr     r0, [r7]
        add     r0, #1
        str     r0, [r7]

        b       1b

print_matches_count:

        ldr     r0, =matches_count
        bl      prntz

        ldr     r0, =colorred
        bl      prntz

        ldr     r0, =matches
        ldr     r0, [r0]
        bl      prntd

        ldr     r0, =colorreset
        bl      prntz

        ldr     r0, =newline
        bl      prntz

        b       exit

usage_error:

        ldr     r0, =usage_err_msg
        bl      prntz

        ldr     r0, =usage
        bl      prntz

        ldr     r0, [sp, #4]
        bl      prntz

        ldr     r0, =args
        bl      prntz

        b       exit

io_error:

        mov     r1, r0
        ldr     r0, =io_err_msg
        bl      prntz
        mvn     r0, r1
        bl      prntd
        ldr     r0, =newline
        bl      prntz

        b       exit

exit:
        eor     r0, r0
        mov     r7, #1
        svc     #0

###############################################################################

printfound:
        # r0 - address of start of the target sequence in source
        # r1 - pointer to target sequence
        push    {r0-r3,lr}

        mov     r2, r0
        mov     r3, r1

        ldr     r1, =printbuf

        ldr     r0, =colorgreen
        bl      strcpy
        add     r1, r0

        ldr     r0, =lineaddr
        ldr     r0, [r0]
        bl      prntxbuf
        add     r1, r0

        ldr     r0, =colorreset
        bl      strcpy
        add     r1, r0

        ldr     r0, =colon
        bl      strcpy
        add     r1, r0

        ldr     r0, =linebuf
        bl      printentry
        add     r1, r0

        ldr     r0, =newline
        bl      strcpy

        ldr     r0, =printbuf
        bl      prntz

        pop     {r0-r3,pc}

###############################################################################

printentry:
        # r0 - source
        # r1 - destination
        # r2 - address of the start of the target sequence
        # r3 - ptr to the target sequence
        push    {r1-r5,lr}
        mov     r5, r1
1:
        cmp     r0, r2
        beq     2f
        ldrb    r4, [r0], #1
        strb    r4, [r1], #1
        b       1b
2:
        mov     r4, r0
        ldr     r0, =colorred
        bl      strcpy
        add     r1, r0
        ldr     r0, =colorbold
        bl      strcpy
        add     r1, r0
        mov     r0, r4
3:
        ldrb    r4, [r3], #1
        tst     r4, r4
        beq     4f
        strb    r4, [r1], #1
        add     r0, #1
        b       3b
4:
        mov     r4, r0
        ldr     r0, =colorreset
        bl      strcpy
        add     r1, r0
        mov     r0, r4
5:
        ldrb    r4, [r0], #1
        strb    r4, [r1], #1
        tst     r4, r4
        bne     5b
        sub     r0, r1, r5
        sub     r0, r0, #1
        pop     {r1-r5,pc}

###############################################################################

prntz:
        # args: r0 - ptr to zero-terminated string
        push    {r0-r2,r7,lr}
        mov     r1, r0
        bl      strlen
        mov     r2, r0
        mov     r0, #1
        mov     r7, #4
        svc     #0
        pop     {r0-r2,r7,pc}

###############################################################################

readfile:
        # args: r0 - ptr to file path
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

###############################################################################

readline:
        # reads a single line from position at r0 into linebuf
        # and updates lineaddr
        # returns ptr to a next line in filebuf
        push    {r1-r2, lr}
        # update lineaddr:
        ldr     r1, =filebuf
        sub     r1, r0, r1
        ldr     r2, =lineaddr
        str     r1, [r2]
        # read next line into linebuf:
        ldr     r1, =linebuf
1:
        ldrb    r2, [r0], #1
        cmp     r2, #0xA
        beq     2f
        strb    r2, [r1], #1
        b       1b
2:
        eor     r2, r2
        strb    r2, [r1]
        pop     {r1-r2, pc}

###############################################################################

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

###############################################################################

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

###############################################################################

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

###############################################################################

strlen:
        # r0 - ptr to zero-terminated string
        push    {r1,lr}
        mov     r1, r0
        bl      strend
        sub     r0, r0, r1
        pop     {r1,pc}

###############################################################################

strcpy:
        # r0 - ptr to source, zero-terminated
        # r1 - ptr to destination
        # returns: number of characters being copied
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

###############################################################################

.data

matches_count:
            .asciz "Total matches: "

io_err_msg:
            .asciz "[Error] Cannot open file, error code: -"

usage_err_msg:
            .asciz "[Error] Unexpected number of arguments.\n"

usage:      .asciz "Usage: "

args:       .asciz " SOURCE_FILE TARGET_SEQUENCE\n"

colorgreen: .asciz "\033[32m"

colorred:   .asciz "\033[31m"

colorbold:  .asciz "\033[1m"

colorreset: .asciz "\033[0m"

colon:      .asciz ": "

newline:    .asciz "\n"

###############################################################################

.bss

###############################################################################

lineaddr:   .space 4

matches:    .space 4

buflen = 1000000

filebuf:    .space buflen
linebuf:    .space buflen
printbuf:   .space buflen
