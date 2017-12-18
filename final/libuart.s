##############################################################################

.text

##############################################################################

UART_MEM        = 0x01C28

CCU_MEM         = 0x01C20

UART1_BIT       = 17

UART1_OFFSET    = 0x0400

UART2_BIT       = 18

UART2_OFFSET    = 0x0800

##############################################################################

libuart_init:
        push    {r1,lr}

        bl      do_parse_args
        tst     r0, r0
        bne     libuart_usage

        ldr     r0, =CCU_MEM
        bl      do_mmap_mem
        ldr     r1, =ccu_mem
        str     r0, [r1]

        ldr     r0, =UART_MEM
        bl      do_mmap_mem
        ldr     r1, =uart_mem
        str     r0, [r1]

        bl      do_setup_uart

        eor     r0, r0
        b       libuart_exit

libuart_usage:
        ldr     r0, =libuart_usage_msg
        bl      prntz
        mvn     r0, #1

libuart_exit:
        pop     {r1,pc}

##############################################################################

do_parse_args:
        # args: r0 = argc, r1 = argv
        # returns: r0 is 0 if success, not zero otherwise

        cmp     r0, #2
        bne     1f

        ldr     r0, [r1, #4]    @ r0 = argv[1]
        ldrb    r0, [r0]        @ r0 = argv[1][0]

        sub     r0, r0, #0x30
        cmp     r0, #1
        beq     2f
        cmp     r0, #2
        beq     2f
1:
        mvn     r0, #1
        mov     pc, lr
2:
        ldr     r1, =uart_no
        str     r0, [r1]
        eor     r0, r0
        mov     pc, lr

##############################################################################

do_setup_uart:
        push    {r0-r4,lr}

        ldr     r1, =uart_no
        ldr     r1, [r1]
        cmp     r1, #1
        ldreq   r1, =UART1_BIT
        ldreq   r4, =UART1_OFFSET
        ldrne   r1, =UART2_BIT
        ldrne   r4, =UART2_OFFSET

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
        add     r1, r1, r4

DLAB_SET        = 0b10000011

        ldr     r0, =DLAB_SET
        ldrb    r2, [r1, #0x0C]
        orr     r2, r2, r0
        strb    r2, [r1, #0x0C]

        mov     r0, #13
        strb    r0, [r1, #0x00]

        eor     r0, r0, r0
        strb    r0, [r1, #0x04]

DLAB_UNSET      = 0b01111111

        ldr     r0, =DLAB_UNSET
        ldrb    r2, [r1, #0x0C]
        and     r2, r2, r0
        strb    r2, [r1, #0x0C]

        pop     {r0-r4,pc}

##############################################################################

# Returns 1 if uart is ready to recv, 0 otherwise.

uart_poll:
        push    {lr}
        bl      get_uart_offset
        ldrb    r0, [r0, #0x14]
        and     r0, r0, #1
        pop     {pc}

##############################################################################

# Returs recieved byte in r0.

uart_recv:
        push    {lr}
        bl      get_uart_offset
        ldrb    r0, [r0, #0x00]
        pop     {pc}

##############################################################################

# Send byte from r0.

uart_send:
        push    {r1,r2,lr}
        mov     r1, r0
        bl      get_uart_offset

1: @ wait clear to send:
        ldrb    r2, [r0, #0x14]
        ands    r2, r2, #0b00100000
        beq     1b

        strb    r1, [r0, #0x00]

        pop     {r1,r2,pc}

##############################################################################

get_uart_offset:
        push    {r1,lr}
        ldr     r0, =uart_no
        ldr     r0, [r0]
        cmp     r0, #1
        ldreq   r0, =UART1_OFFSET
        ldrne   r0, =UART2_OFFSET
        ldr     r1, =uart_mem
        ldr     r1, [r1]
        add     r0, r0, r1
        pop     {r1,pc}

##############################################################################

.data

##############################################################################

libuart_usage_msg:
                .ascii "Usage: a.out UART\n\n"
                .ascii "Parameters:\n"
                .asciz "    UART - uart port to use (1 or 2)\n\n"

##############################################################################

.bss

##############################################################################

ccu_mem:        .space 4

uart_mem:       .space 4

uart_no:        .space 4

##############################################################################
