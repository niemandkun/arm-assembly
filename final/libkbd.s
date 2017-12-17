##############################################################################
#
# libkbd.s
#
# Contains procedures to handle terminal input canonical way.
#
##############################################################################

.global canon
.global nocanon
.global kbdhit

##############################################################################

canon:
        push    {r0-r3,lr}

STDIN           = 1

        mov     r0, $STDIN
        ldr     r1, =termios_old
        bl      tcgetattr   @tcgetattr(STDIN, &termios_old)

TERMIOS_SIZE    = 60
REGISTER_SIZE   = 4

        mov     r0, $TERMIOS_SIZE
        ldr     r1, =termios_old
        ldr     r2, =termios_new
1:
        subs    r0, $REGISTER_SIZE
        ldr     r3, [r1, r0]
        ldr     r3, [r2, r0]
        bne     1b

C_LFLAG         = 12
ICANON          = 2
ECHO            = 8
NOECHO          = ~(ECHO | ICANON)

        ldr     r0, [r2, $C_LFLAG]
        mov     r1, $NOECHO
        and     r0, r0, r1
        str     r0, [r2, $C_LFLAG]

TCSANOW         = 0

        mov     r0, $STDIN
        mov     r1, $TCSANOW
        ldr     r2, =termios_new
        bl      tcsetattr

        pop     {r0-r3,pc}

##############################################################################

nocanon:
        push    {r0-r2,lr}

        mov     r0, $STDIN
        mov     r1, $TCSANOW
        ldr     r2, =termios_old
        bl      tcsetattr

        pop     {r0-r2,pc}

##############################################################################

kbdhit:
        push    {r1-r12,lr}

FIONREAD        = 0x541B

        mov     r0, $STDIN
        ldr     r1, =FIONREAD
        ldr     r2, =kbdhit_n
        bl      ioctl
        ldr     r0, [r2]

        pop     {r1-r12,pc}

##############################################################################

.bss

##############################################################################

kbdhit_n:       .space REGISTER_SIZE

termios_old:    .space TERMIOS_SIZE

termios_new:    .space TERMIOS_SIZE

##############################################################################

# EoF
