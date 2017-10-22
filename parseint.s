################################################################################
#                                                                              #
#                              PINK FACTORIAL                                  #
#                                                                              #
#                      Prints pink factorial of a number.                      #
#                                                                              #
################################################################################

                                .global main

################################################################################
#                                                                              #
#                                 CONSTANTS                                    #
#                                                                              #
################################################################################

C_LFLAG                                                                     = 12

ECHO                                                                         = 8

ICANON                                                                       = 2

TCSANOW                                                                      = 0

STDIN_FILENO                                                                 = 0

SIZEOF_TERMIOS                                                              = 60

RSIZE                                                                        = 4

BAD_LUCK                                                                    = -1

SATAN_NUMBER                                                                = 13

NOECHO                                                        = ~(ECHO | ICANON)

################################################################################
#                                                                              #
#                                   MACROS                                     #
#                                                                              #
################################################################################


.macro esc command
        ldr     r0, =\command
        bl      do_esc
.endm

.macro sett t_ptr
        mov     r0, #STDIN_FILENO
        mov     r1, #TCSANOW
        mov     r2, \t_ptr
        bl      tcsetattr
.endm

.macro gett t_ptr
        mov     r0, #STDIN_FILENO
        mov     r1, \t_ptr
        bl      tcgetattr
.endm


################################################################################
#                                                                              #
                                    .text
#                                                                              #
################################################################################

main:   number  .req r8
        push    {lr}
        bl      geti
        cmp     r0, #BAD_LUCK
        popeq   {pc}
        mov     number, r0
        esc     clear
        esc     voffset
        esc     hoffset
        esc     pink
        esc     bold
        mov     r0, number
        bl      prnt
        ldr     r0, =fact_sign
        bl      printf
        mov     r0, number
        bl      fact
        bl      prnt
        esc     vstart
        esc     hstart
        bl      getch
        ldr     r0, =reset
        bl      printf
        pop     {pc}

################################################################################

# Parse integer. r0 is ptr to char array, zero terminated.

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
        mla     acc, acc, base, char
        b       1b
2:
        mov     r0, acc
        pop     {pc}

################################################################################

# Get positive integer in r0. Returns -1 if error.

geti:   push    {lr}
        cmp     r0, #2
        movne   r0, #BAD_LUCK
        popne   {pc}
        ldr     r0, [r1, #4]
        bl      parse
        cmp     r0, #SATAN_NUMBER
        movge   r0, #BAD_LUCK
        popge   {pc}
        tst     r0, r0
        movlt   r0, #BAD_LUCK
        pop     {pc}

################################################################################

# Get console input silently

getch:  told_p  .req r4
        tnew_p  .req r5
        push    {lr}
        ldr     told_p, =told
        ldr     tnew_p, =tnew
        gett    told_p
        bl      copy_t
        bl      echoff
        sett    tnew_p
        bl      getchar
        sett    told_p
        bl      tcsetattr
        pop     {pc}

################################################################################

# Copy bytes from told to tnew

copy_t: offset  .req r0
        buf     .req r1
        eor     offset, offset
1:      ldr     buf, [told_p, offset]
        str     buf, [tnew_p, offset]
        add     offset, #RSIZE
        cmp     offset, #SIZEOF_TERMIOS
        bne     1b
        mov     pc, lr

################################################################################

# Writes flag required to disable console output

echoff: ldr     r0, [tnew_p, $C_LFLAG]
        mov     r1, #NOECHO
        and     r0, r0, r1
        str     r0, [tnew_p, $C_LFLAG]
        mov     pc, lr

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

# args:         r0  address of escape sequence

# Prints escape-sequence.

do_esc: push    {r0, r1, lr}
        ldr     r1, [r0]
        ldr     r0, =cmd_buf
        str     r1, [r0]
        ldr     r0, =escape_seq
        bl      printf
        pop     {r0, r1, pc}

################################################################################

# args:         r0 integer to print

# Printing unsigned integer with space as thousands separator.

prnt:   push    {r0-r7, lr}
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
#                                                                              #
                                    .data
#                                                                              #
################################################################################

told:           .space SIZEOF_TERMIOS

tnew:           .space SIZEOF_TERMIOS

scan:           .space RSIZE

fact_sign:      .asciz "! = "

scanf_fmt:      .asciz "%i"

escape_seq:     .ascii "\033["

cmd_buf:        .space 4

num_buf:        .space 128

clear:          .asciz "2J"

voffset:        .asciz "12d"

hoffset:        .asciz "36G"

vstart:         .asciz "0d"

hstart:         .asciz "0G"

pink:           .asciz "31m"

bold:           .asciz "1m"

reset:          .asciz "\033c"

################################################################################
#                                                                              #
#                                    EOF                                       #
#                                                                              #
################################################################################
