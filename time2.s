.global main

.include "libprint.s"

.include "libstring.s"

.include "libkbd.s"

##############################################################################

.text

##############################################################################

main:
        push    {lr}

        bl      do_mmap_rtc_mem
        tst     r1, r1
        blt     exit_error

        bl      canon

UPDATE          = 0x000fffff

        ldr     r10, =UPDATE
        mov     r11, r0
        eor     r12, r12

        ldr     r0, =is_alive
        mov     r1, #1
        str     r1, [r0]

loop:
        and     r1, r12, r10
        add     r12, r12, #1

        tst     r1, r1
        bne     loop

loop_kbd_check:

        bl      kbdhit
        tst     r0, r0
        beq     loop_is_alive_check

        bl      getchar

        cmp     r0, #0x0D @ carriage return
        beq     cleanup
        cmp     r0, #0x0A @ new line
        beq     cleanup
        cmp     r0, #0x03 @ ^C
        beq     cleanup

        ldr     r0, =is_alive
        ldr     r1, [r0]
        mvn     r1, r1
        and     r1, r1, #1
        str     r1, [r0]

loop_is_alive_check:
        ldr     r0, =is_alive
        ldr     r1, [r0]
        mov     r0, r1
        tst     r1, r1
        beq     loop

loop_update:
        mov     r0, r11
        bl      printtime
        b       loop

exit_error:
        ldr     r0, =error_msg
        bl      prntz
        b       exit

cleanup:
        bl      nocanon
        bl      do_close_rtc_mem
        ldr     r0, =reset
        bl      prntz

exit:
        pop     {pc}

##############################################################################

do_mmap_rtc_mem:
        # args: none
        # returns: address of allocation start
        # r1 = 0 if no error, r1 != 0 otherwise
        push    {r2-r7,lr}

O_RDWR          = 0x0002
O_DSYNC         = 0x1000

OPEN_FLAGS      = O_RDWR | O_DSYNC

        ldr     r0, =memfile
        ldr     r1, =OPEN_FLAGS
        mov     r7, #5
        svc     #0  @open(memfile)

        tst     r0, r0
        mvnlt   r1, #1
        blt     1f

        ldr     r1, =filedesc
        str     r0, [r1]

PROT_READ       = 0x0001
PROT_WRITE      = 0x0002
MAP_SHARED      = 0x0001

MMAP_PROT       = PROT_READ | PROT_WRITE
MMAP_FLAGS      = MAP_SHARED
rtc_base        = 0x1f00

        mov     r4, r0
        eor     r0, r0
        mov     r1, #1
        mov     r2, #MMAP_PROT
        mov     r3, #MMAP_FLAGS
        ldr     r5, =rtc_base
        mov     r7, #192
        svc     #0  @mmap2(0, 1, MMAP_PROT, MMAP_FLAGS, 0, rtc_base_addr)

        eor     r1, r1

1:
        pop     {r2-r7,pc}

##############################################################################

do_close_rtc_mem:
        push    {r0,r7,lr}
        ldr     r0, =filedesc
        ldr     r0, [r0]
        mov     r7, #6
        svc     #0  @close(filedesc)
        pop     {r0,r7,pc}

##############################################################################

printtime:
        # args: r0 - address of allocation start
        push    {r0-r4,r7,r8,lr}
        mov     r8, r0

TIME_MASK       = 0xff
YEAR_OFFSET     = 1970

        ldr     r1, =printbuf
        ldr     r2, =TIME_MASK
        ldr     r4, =YEAR_OFFSET

print_date:
        ldr     r3, [r8, #16]

        and     r0, r3, r2
        bl      prntdbuf
        add     r1, r0

        bl      add_dot

        ror     r3, r3, #8
        and     r0, r3, r2
        bl      prntdbuf
        add     r1, r0

        bl      add_dot

        ror     r3, r3, #8
        and     r0, r3, r2
        add     r0, r0, r4
        bl      prntdbuf
        add     r1, r0

        bl      add_space

print_time:
        ldr     r3, [r8, #20]
        rev     r3, r3

BLINK_FLAG      = 0x10000000

        ldr     r4, =BLINK_FLAG
        and     r4, r4, r12

        ror     r3, r3, #8
        and     r0, r3, r2
        bl      prntdbuf
        add     r1, r0

        tst     r4, r4
        bleq    add_colon
        blne    add_space

        ror     r3, r3, #8
        and     r0, r3, r2
        bl      prntdbuf
        add     r1, r0

        tst     r4, r4
        bleq    add_colon
        blne    add_space

        ror     r3, r3, #8
        and     r0, r3, r2
        bl      prntdbuf
        add     r1, r0

STDOUT          = 1

        mov     r0, #STDOUT
        ldr     r1, =printstart
        ldr     r2, =printlen
        mov     r7, #4
        svc     #0  @write(STDOUT, printstart, printlen)

        pop     {r0-r4,r7,r8,pc}


##############################################################################

.macro insert_char char
        mov     r0, \char @ dot
        strb    r0, [r1], #1
        mov     pc, lr
.endm

##############################################################################

add_dot:
        insert_char #0x2E

##############################################################################

add_space:
        insert_char #0x20

##############################################################################

add_colon:
        insert_char #0x3A

##############################################################################

.data

##############################################################################

memfile:        .asciz "/dev/mem"

printstart:     .ascii "\033[2J"    @ clear
                .ascii "\033[12d"   @ voffset
                .ascii "\033[33G"   @ offset
                .ascii "\033[40m"   @ bg color
                .ascii "\033[32m"   @ fg color
                .ascii "\033[1m"    @ bold

printbuf:       .space 19

                .ascii "\033[0d"    @ voffset
                .ascii "\033[0G"    @ offset
                .ascii "\033[0m"    @ reset color

printlen        = . - printstart

reset:          .asciz "\033c"

POLLIN          = 0x01
STDIN           = 0x02

pollfd:
                .word STDIN
                .hword POLLIN
                .hword 0

error_msg:      .asciz "[Error] Cannot open /dev/mem, aborting.\n"

##############################################################################

.bss

##############################################################################

filedesc:       .space 4

is_alive:       .space 4

##############################################################################

# EoF
