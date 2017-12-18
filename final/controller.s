##############################################################################

.text

##############################################################################

SCROLL_SPEED    = 2

WAIT_OK_CYCLES  = 0x00020000

RETRY_COUNT     = 3

SYNC_INTERVAL   = 1

SYNC_WAIT       = 5

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
        bl      add_msg_to_hist

        bl      send_message
        bl      print_error

        ldr     r1, =msg_end
        ldr     r0, =msg_buf
        str     r0, [r1]

        b       finish

finish:
        pop     {r0-r2,pc}

##############################################################################

# Args: r0 -- error state (1 error, 0 no errors).

print_error:
        push    {r0,r1,lr}

        tst     r0, r0
        beq     1f

        ldr     r0, =error_msg_send
        ldr     r1, =system_nick
        bl      add_msg_to_hist

1: @ ok:
        pop     {r0,r1,pc}

##############################################################################

check_uart_input:
        push    {r0-r2,lr}

        bl      uart_poll
        tst     r0, r0
        beq     4f

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

        sub     r0, r2, r1
        cmp     r0, #2
        blt     4f

        ldrb    r0, [r2, #-2]
        cmp     r0, #0x0A

        bleq    run_command

4: @ finish:
        pop     {r0-r2,pc}

##############################################################################

# Args: r0 - ptr to message (zero-terminated).

# Returns: r0 = 0 if send successfull, r0 != 0 otherwise.

send_message:
        push    {r1-r2,lr}

        mov     r2, r0

        ldr     r1, =out_net_buf
        ldr     r0, =cmd_msg
        bl      strcpy
        add     r1, r1, r0

        mov     r0, r2
        bl      strcpy
        add     r1, r1, r0

        mov     r0, #0x0A
        str     r0, [r1], #1

        bl      write_checksum
        
        ldr     r2, =RETRY_COUNT
1:
        bl      send_buffer
        bl      wait_ok
        tst     r0, r0
        beq     2f

        subs    r2, #1
        beq     2f

        b       1b
2:
        pop     {r1-r2,pc}

##############################################################################

send_nick:
        push    {r0-r2,lr}

        ldr     r1, =out_net_buf
        ldr     r0, =cmd_name
        bl      strcpy
        add     r1, r1, r0

        ldr     r0, =self_nick
        bl      strcpy
        add     r1, r1, r0

        mov     r0, #0x0A
        str     r0, [r1], #1

        bl      write_checksum

        ldr     r2, =RETRY_COUNT
1:
        bl      send_buffer
        bl      wait_ok
        tst     r0, r0
        beq     2f

        subs    r2, #1
        beq     2f

        b       1b
2:
        pop     {r0-r2,pc}

##############################################################################

send_ok:
        push    {r0,r1,lr}

        ldr     r0, =cmd_ok
        ldr     r1, =out_net_buf
        bl      strcpy
        add     r1, r1, r0

        mov     r0, #0x0A
        str     r0, [r1], #1

        bl      write_checksum

        bl      send_buffer

        pop     {r0,r1,pc}

##############################################################################

send_sync:
        push    {r0,r1,lr}

        ldr     r0, =cmd_sync
        ldr     r1, =out_net_buf
        bl      strcpy
        add     r1, r1, r0

        mov     r0, #0x0A
        str     r0, [r1], #1

        bl      write_checksum

        bl      send_buffer

        pop     {r0,r1,pc}

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

        ldrb    r0, [r2], #1
        bl      uart_send

        b       1b
2:
        pop     {r0-r2,pc}

##############################################################################

# Wait /ok message from uart port.
# Args: none. Returns: r0 if OK, 1 otherwise.

wait_ok:
        push    {r1-r2,lr}

        eor     r0, r0
        ldr     r1, =ok_flag
        str     r0, [r1]        @ reset ok_flag

        ldr     r2, =WAIT_OK_CYCLES

1: @ run cycle to wait /ok message.
        bl      check_uart_input
        ldr     r0, [r1]
        tst     r0, r0
        bne     2f

        subs    r2, #1
        beq     3f

        b       1b

2: @ OK:
        eor     r0, r0
        b       4f

3: @ not so OK:
        mov     r0, #1
        b       4f

4: @ finish:
        pop     {r1-r2,pc}

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

        ldr     r0, =cmd_name
        bl      cmppref
        tst     r0, r0
        beq     2f

        ldr     r0, =cmd_ok
        bl      cmppref
        tst     r0, r0
        beq     3f

        ldr     r0, =cmd_sync
        bl      cmppref
        tst     r0, r0
        beq     4f

        b       99f

1: @ recive message:
        ldr     r0, =cmd_msg
        bl      strlen
        add     r1, r0

        mov     r0, r1
        ldr     r1, =other_nick
        bl      add_msg_to_hist
        bl      send_ok
        b       99f

2: @ change name:
        ldr     r0, =cmd_name
        bl      strlen
        add     r1, r0

        mov     r0, r1
        ldr     r1, =other_nick
        bl      strcpy
        bl      send_ok
        ldr     r0, =nick_msg
        bl      notify_nick_changed
        b       99f

3: @ ok:
        mov     r0, #1
        ldr     r1, =ok_flag
        str     r0, [r1]
        b       99f

4: @ sync:
        bl      get_current_time
        ldr     r1, =last_sync_recv
        str     r0, [r1]
        b       99f

99: @ finish run_command:
        ldr     r0, =in_net_buf
        ldr     r1, =in_net_buf_end
        str     r0, [r1]

        pop     {r0-r2,pc}

##############################################################################

# r0 - message (zero terminated)
# r1 - nick

notify_nick_changed:
        push    {r0-r2,lr}

        mov     r2, r1

        ldr     r1, =in_net_buf
        bl      strcpy
        add     r1, r1, r0

        mov     r0, r2
        bl      strcpy
        add     r1, r1, r0

        ldr     r0, =in_net_buf
        ldr     r1, =system_nick
        bl      add_msg_to_hist

        pop     {r0-r2,pc}

##############################################################################

check_sync_state:
        push    {r0-r3,lr}

        bl      get_current_time

        ldr     r1, =last_sync_sent
        ldr     r2, [r1]
        sub     r2, r0, r2

        cmp     r2, #SYNC_INTERVAL
        strge   r0, [r1]
        blge    send_sync

        ldr     r1, =last_sync_recv
        ldr     r2, [r1]
        sub     r2, r0, r2

        ldr     r1, =system_nick
        ldr     r3, =online_flag

        cmp     r2, #SYNC_WAIT
        ble     2f

1: @ come offline:
        ldr     r0, =offline_msg
        ldr     r2, [r3]
        tst     r2, r2
        blne    add_msg_to_hist
        eor     r0, r0
        str     r0, [r3]
        b       3f

2: @ come online:
        ldr     r0, =online_msg
        ldr     r2, [r3]
        tst     r2, r2
        bne     3f

4: @ should send sync information:
        bl      add_msg_to_hist
        mov     r0, #1
        str     r0, [r3]
        bl      send_nick

3: @ finish
        pop     {r0-r3,pc}

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

last_sync_sent: .space 4
last_sync_recv: .space 4

ok_flag:        .space 4

in_net_buf_end: .space 4

out_net_buf:    .space 1000
in_net_buf:     .space 1000

##############################################################################
