.global _start

.include "libprint.s"

###############################################################################

.text

###############################################################################

_start:
        ldr     r0, =filehandle
        ldr     r1, =filebuf
        eor     r2, r2
8:
        str     r2, [r0], #1
        cmp     r0, r1
        bne     8b

        ldr     r0, [sp]
        cmp     r0, #3
        bne     usage_error

        ldr     r0, [sp, #8]
        bl      openfile
        tst     r0, r0
        ble     io_error

        ldr     r0, =reset
        bl      prntz

        ldr     r1, [sp, #12]
        # r1 = ptr to target sequence

        ldr     r2, =linebuf
        # r2 = ptr to linebuf

1:
        bl      readline
        tst     r0, r0
        blt     print_matches_count

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

        bl      closefile

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

openfile:
        # args: r0 - ptr to file path
        push    {r1,r7,lr}
        eor     r1, r1
        mov     r7, #5
        svc     #0
        ldr     r1, =filehandle
        str     r0, [r1]
        pop     {r1,r7,pc}

###############################################################################

readfile:
        # args: none
        # returns count of bytes being read
        push    {r1,r2,r7,lr}
        ldr     r0, =filehandle
        ldr     r0, [r0]
        ldr     r1, =filebuf
        ldr     r2, =buflen
        mov     r7, #3
        svc     #0
        ldr     r1, =readlen
        str     r0, [r1]
        pop     {r1,r2,r7,pc}

###############################################################################

closefile:
        # args: none
        push    {r0,r1,lr}
        ldr     r1, =filehandle
        ldr     r0, [r1]
        mov     r7, #6
        svc     #0
        eor     r0, r0
        str     r0, [r1]
        pop     {r0,r1,pc}

###############################################################################

readline:
        # args: none
        # reads a single line into linebuf, updates lineaddr
        # returns length of the line if succ, or -1 if file is empty
        push    {r1-r9,lr}

        # update lineaddr:
        ldr     r2, =lineaddr
        ldr     r0, [r2]

        ldr     r1, =linelen
        ldr     r1, [r1]

        add     r0, r0, r1
        str     r0, [r2]

        # read next line:

        ldr     r1, =linebuf

        ldr     r2, =filebuf

        ldr     r3, =nextline
        ldr     r3, [r3]

        ldr     r4, =readlen
        ldr     r4, [r4]

        add     r5, r2, r4
        # r5 = address of byte after the last file byte in buffer

        ldr     r6, =buflen
        add     r6, r6, r2
        # r6 = address of byte after the last buffer byte

        add     r7, r2, r3
        # r7 = current byte to read from filebuf

        mov     r8, #0x0A
        # r8 = newline character

        eor     r9, r9
        # r9 = length of the line
1:
        cmp     r7, r5
        blt     2f

        bl      readfile
        tst     r0, r0
        mvneq   r9, #1
        beq     3f

        mov     r4, r0
        add     r5, r2, r4
        mov     r7, r2
2:
        ldrb    r0, [r7], #1
        add     r9, r9, #1
        cmp     r0, r8
        beq     3f

        strb    r0, [r1], #1
        b       1b

3:
        eor     r0, r0
        strb    r0, [r1]

        ldr     r0, =nextline
        sub     r7, r7, r2
        str     r7, [r0]

        ldr     r0, =linelen
        str     r9, [r0]

        mov     r0, r9
        pop     {r1-r9,pc}

###############################################################################

#beginread:
#        # args: none
#        # reads file if buffer is empty and updates readlen
#        push    {lr}
#
#        ldr     r0, =readlen
#        ldr     r1, [=readlen]
#        # r1 = count of bytes in the filebuf
#
#        tst     r1, r1
#        bne     1f
#
#        # buffer is empty:
#        bl      readfile
#        # check: if read zero bytes, file is empty
#        tst     r0, r0
#        mvneq   r0, #1
#1:
#        pop     {pc}

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
            .asciz "\nTotal matches: "

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

reset:      .asciz "\033[2J\033[0d\033[0G"

###############################################################################

.bss

###############################################################################

# handle for opened file
filehandle: .space 4

# offset of current line in file
lineaddr:   .space 4

# count of matched lines in file
matches:    .space 4

# count of meaningful bytes in filebuf
readlen:    .space 4

# relative to filebuf
nextline:   .space 4

# length of current line
linelen:    .space 4

buflen = 1000000

filebuf:    .space buflen
linebuf:    .space buflen
printbuf:   .space buflen
