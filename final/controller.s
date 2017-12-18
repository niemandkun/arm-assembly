##############################################################################

.text

##############################################################################

SCROLL_SPEED    = 2

##############################################################################

controller_init:
        push    {r0,r1,lr}

        ldr     r0, =in_net_buf
        ldr     r1, =in_net_buf_end
        str     r0, [r1]

        pop     {r0,r1,pc}

##############################################################################

# Args: r0 - length of input
#       r1 - ptr to input array

handle_tui_input:
        push    {r0-r2,lr}

        cmp     r0, #1
        bne     handle_escape_seq

single_character:
        ldrb    r0, [r1]

        cmp     r0, #0x7F
        beq     backspace

        cmp     r0, #0x0D
        beq     return

        cmp     r0, #0x0A
        beq     return

        cmp     r0, #0x20
        blt     finish

        cmp     r0, #0x7E
        bgt     finish

printable_character:
        ldr     r1, =msg_end
        ldr     r2, [r1]
        strb    r0, [r2], #1
        str     r2, [r1]
        b       finish

handle_escape_seq:
        cmp     r0, #3
        bne     finish

        ldrb    r0, [r1]
        cmp     r0, #0x1B
        bne     finish

        ldrb    r0, [r1, #1]
        cmp     r0, #0x5B
        bne     finish

        ldrb    r0, [r1, #2]
        cmp     r0, #0x41
        beq     arrow_up

        cmp     r0, #0x42
        beq     arrow_down
        b       finish

backspace:
        ldr     r1, =msg_end
        ldr     r0, [r1]
        ldr     r2, =msg_buf
        cmp     r0, r2
        beq     finish

        sub     r0, #1
        str     r0, [r1]

        ldrb    r2, [r0, #-1]!
        cmp     r2, #0x0D
        streq   r0, [r1]

        b       finish

arrow_up:
        ldr     r1, =hist_scroll
        ldr     r0, [r1]
        add     r0, #SCROLL_SPEED
        str     r0, [r1]
        b       finish

arrow_down:
        ldr     r1, =hist_scroll
        ldr     r0, [r1]
        cmp     r0, #0
        beq     finish
        sub     r0, #SCROLL_SPEED
        str     r0, [r1]
        b       finish

return:
        ldr     r1, =msg_end
        ldr     r1, [r1]
        ldr     r2, =msg_buf
        cmp     r1, r2
        beq     finish

        eor     r0, r0
        str     r0, [r1]

        ldr     r0, =msg_buf
        ldr     r1, =self_nick
        bl      send_message

        ldr     r1, =msg_end
        ldr     r0, =msg_buf
        str     r0, [r1]

        b       finish

finish:
        pop     {r0-r2,pc}

##############################################################################

check_uart_input:
        push    {r0-r2,lr}

        bl      uart_poll
        tst     r0, r0
        beq     1f

        bl      uart_recv

        ldr     r1, =in_net_buf
        ldr     r2, =in_net_buf_end
        ldr     r2, [r2]

        cmp     r2, r1
        bne     3f

2: @ recieve start of message: ('/' character):
        cmp     r0, #0x2F
        bne     1f

3: @store byte in buffer
        strb    r0, [r2], #1
        ldr     r0, =in_net_buf_end
        str     r2, [r0]

1: @ check end of transmission:

        sub     r1, r2, r1
        cmp     r1, #2
        blt     4f

        ldrb    r0, [r2, #-2]
        cmp     r0, #0x0A

        bleq    run_command

4: @ finish:
        pop     {r0-r2,pc}

##############################################################################

# Args: r0 - ptr to message (zero-terminated)

send_message:
        push    {r0-r2,lr}

        ldr     r1, =self_nick
        bl      add_msg_to_hist

        mov     r2, r0

        ldr     r1, =out_net_buf
        ldr     r0, =cmd_msg
        bl      strcpy
        add     r1, r0

        mov     r0, r2
        bl      strcpy
        add     r1, r0

        mov     r0, #0x0A
        str     r0, [r1], #1

        bl      write_checksum

        bl      send_buffer

        pop     {r0-r2,pc}

##############################################################################

# Args: r1 - buffer end (exclusive)
# Returns: r1 - buffer end after writing checksum (exclusive)

write_checksum:
        push    {r0,r2,r3,lr}

        ldr     r0, =out_net_buf    @ ptr
        eor     r2, r2              @ checksum
1:
        ldrb    r3, [r0], #1
        add     r2, r3
        cmp     r0, r1
        bne     1b

        strb    r2, [r1], #1

        pop     {r0,r2,r3,pc}

##############################################################################

# Send content of uart_buffer over uart.

# Args: r1 - buffer end (exclusive).

send_buffer:
        push    {r0-r2,lr}

        ldr     r2, =out_net_buf
1:
        cmp     r2, r1
        beq     2f

        ldrb    r0, [r2]
        bl      uart_send

        add     r2, #1
        b       1b
2:
        pop     {r0-r2,pc}

##############################################################################

# Args: r0 - ptr to message (zero-terminated)
#       r1 - ptr to nick (zero-terminated)

add_msg_to_hist:
        push    {r0-r4,lr}

        mov     r2, r0  @ message
        mov     r3, r1  @ nick

        ldr     r4, =hist_end
        ldr     r1, [r4]

        mov     r0, #0x0D
        str     r0, [r1], #1
        mov     r0, #0x0A
        str     r0, [r1], #1    @ write \n

        mov     r0, r3
        bl      strcpy          @ write nickname
        add     r1, r0

        mov     r0, #0x20       @ write space
        str     r0, [r1], #1

        mov     r0, #0x28       @ write (
        str     r0, [r1], #1

        bl      print_time      @ write timestamp
        add     r1, r1, r0

        mov     r0, #0x29       @ write )
        str     r0, [r1], #1

        mov     r0, #0x3A       @ write :
        str     r0, [r1], #1

        mov     r0, #0x20       @ write space
        str     r0, [r1], #1

        mov     r0, r2
        bl      strcpy          @ write message
        add     r1, r1, r0

        mov     r0, #0x0D
        str     r0, [r1], #1
        mov     r0, #0x0A
        str     r0, [r1], #1

        str     r1, [r4]

        ldr     r1, =hist_scroll
        eor     r0, r0
        str     r0, [r1]

        pop     {r0-r4,pc}

##############################################################################

run_command:
        push    {r0-r2,lr}

        ldr     r0, =in_net_buf_end
        ldr     r0, [r0]
        eor     r2, r2
        strb    r2, [r0, #-2]   @ replace "\n" with 0x00

        ldr     r1, =in_net_buf

        ldr     r0, =cmd_msg
        bl      cmppref
        tst     r0, r0
        beq     1f

        b       99f

1: @ recive message:
        ldr     r0, =cmd_msg
        bl      strlen
        add     r1, r0

        mov     r0, r1
        ldr     r1, =other_nick
        bl      add_msg_to_hist
        b       99f

99: @ finish run_command:
        ldr     r0, =in_net_buf
        ldr     r1, =in_net_buf_end
        str     r0, [r1]

        pop     {r0-r2,pc}

##############################################################################

.data

##############################################################################

cmd_msg:        .asciz "/msg "
cmd_name:       .asciz "/name "
cmd_ok:         .asciz "/ok"
cmd_sync:       .asciz "/sync"

##############################################################################

.bss

##############################################################################

in_net_buf_end: .space 4

out_net_buf:    .space 1000
in_net_buf:     .space 1000

##############################################################################
