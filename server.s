##############################################################################

.global main

.include "libkbd.s"

.include "libprint.s"

.include "libstring.s"

##############################################################################

.text

##############################################################################

main:
        push    {lr}

        bl      do_open_memfile

        tst     r0, r0
        blt     error

        ldr     r1, =filedesc
        str     r0, [r1]

CCU_MEM         = 0x01C20

        ldr     r1, =filedesc
        ldr     r0, [r1]
        ldr     r1, =CCU_MEM
        bl      do_mmap_mem
        ldr     r1, =ccu_mem
        str     r0, [r1]

UART_MEM        = 0x01C28

        ldr     r1, =filedesc
        ldr     r0, [r1]
        ldr     r1, =UART_MEM
        bl      do_mmap_mem
        ldr     r1, =uart_mem
        str     r0, [r1]

        bl      do_setup_uart

        bl      canon

        bl      do_job

        b       cleanup

error:
        ldr     r0, =error_msg
        bl      prntz
        b       exit

cleanup:
        bl      do_close_memfile
        bl      nocanon

exit:
        pop     {pc}

##############################################################################

do_setup_uart:
        push    {r0-r3,lr}

UART_BIT        = 17 @ UART1
UART_OFFSET     = 0x0400

# UART_BIT        = 18 @ UART2
# UART_OFFSET     = 0x0800

        ldr     r1, =UART_BIT
        mov     r0, #1
        lsl     r0, r0, r1

        ldr     r1, =ccu_mem
        ldr     r1, [r1]

        ldr     r2, [r1, #0x006C]
        orr     r2, r2, r0
        str     r2, [r1, #0x006C]

        ldr     r2, [r1, #0x02D8]
        orr     r2, r2, r0
        str     r2, [r1, #0x02D8]

        ldr     r1, =uart_mem
        ldr     r1, [r1]

DLAB_SET        = 0b10000011

        ldr     r0, =DLAB_SET
        ldrb    r2, [r1, #UART_OFFSET + 0x0C]
        orr     r2, r2, r0
        strb    r2, [r1, #UART_OFFSET + 0x0C]

        mov     r0, #13
        strb    r0, [r1, #UART_OFFSET + 0x00]

        eor     r0, r0, r0
        strb    r0, [r1, #UART_OFFSET + 0x04]

DLAB_UNSET      = 0b01111111

        ldr     r0, =DLAB_UNSET
        ldrb    r2, [r1, #UART_OFFSET + 0x0C]
        and     r2, r2, r0
        strb    r2, [r1, #UART_OFFSET + 0x0C]

        pop     {r0-r3,pc}

##############################################################################

do_job:
        push    {r0-r3,r7,lr}

STDOUT          = 1

job_start:

check_icoming_message:

        ldr     r3, =uart_mem
        ldr     r3, [r3]
        ldrb    r0, [r3, #UART_OFFSET + 0x14]
        ands    r0, r0, #1
        beq     check_outcoming_message

recv_incoming_message:

        ldr     r1, =printbuf
        ldrb    r0, [r3, #UART_OFFSET + 0x00]
        strb    r0, [r1]
        mov     r0, #STDOUT
        mov     r2, #1
        mov     r7, #4
        svc     #0  @write(STDOUT, printfuf, 1);

check_outcoming_message:

        bl      kbdhit
        tst     r0, r0
        beq     job_start

send_outcoming_message:

        bl      getchar

        cmp     r0, #0x03 @ ^C
        beq     job_finish

        ldr     r3, =uart_mem
        ldr     r3, [r3]

wait_port_empty:

        ldrb    r1, [r3, #UART_OFFSET + 0x14]
        ands    r1, r1, #0b00100000
        # beq     wait_port_empty

        strb    r0, [r3, #UART_OFFSET + 0x00]

        b       job_start

job_finish:

        pop     {r0-r3,r7,pc}

##############################################################################

do_open_memfile:
        # args: none
        # returns: fd for memfile
        push    {r1-r7,lr}

O_RDWR          = 0x0002
O_DSYNC         = 0x1000
OPEN_FLAGS      = O_RDWR | O_DSYNC

        ldr     r0, =memfile
        ldr     r1, =OPEN_FLAGS
        mov     r7, #5
        svc     #0  @open(memfile)

        pop     {r1-r7,pc}

##############################################################################

do_close_memfile:
        push    {r0,r7,lr}
        ldr     r0, =filedesc
        ldr     r0, [r0]
        mov     r7, #6
        svc     #0  @close(filedesc)
        pop     {r0,r7,pc}

##############################################################################

do_mmap_mem:
        # args: r0 - memfile descriptor
        # args: r1 - offset of memory to be mmaped
        # returns: r0 - address of allocation start
        push    {r1-r7,lr}

        mov     r5, r1

PROT_READ       = 0x0001
PROT_WRITE      = 0x0002
MAP_SHARED      = 0x0001

MMAP_PROT       = PROT_READ | PROT_WRITE
MMAP_FLAGS      = MAP_SHARED

        eor     r0, r0
        mov     r1, #4096
        mov     r2, #MMAP_PROT
        mov     r3, #MMAP_FLAGS
        ldr     r4, =filedesc
        ldr     r4, [r4]
        mov     r7, #192
        svc     #0  @mmap2(0, 1, MMAP_PROT, MMAP_FLAGS, filedesc, base_addr)

        pop     {r1-r7,pc}

##############################################################################

.data

##############################################################################

memfile:        .asciz "/dev/mem"

error_msg:      .asciz "[Error] Cannot open /dev/mem, aborting.\n"

##############################################################################

.bss

##############################################################################

printbuf:       .space 1

filedesc:       .space 4

ccu_mem:        .space 4

uart_mem:       .space 4

##############################################################################

# EoF
