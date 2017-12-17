##############################################################################

.text

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
        beq     ctrl_enter

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
        add     r0, #1
        str     r0, [r1]
        b       finish

arrow_down:
        ldr     r1, =hist_scroll
        ldr     r0, [r1]
        cmp     r0, #0
        beq     finish
        sub     r0, #1
        str     r0, [r1]
        b       finish

return:
        ldr     r1, =msg_end
        ldr     r2, [r1]
        mov     r0, #0x0D
        strb    r0, [r2], #1
        mov     r0, #0x0A
        strb    r0, [r2], #1
        str     r2, [r1]
        b       finish

ctrl_enter:
        ldr     r1, =msg_end
        ldr     r1, [r1]
        ldr     r2, =msg_buf
        cmp     r1, r2
        beq     finish

        eor     r0, r0
        str     r0, [r1]

        ldr     r0, =msg_buf
        ldr     r1, =self_nick
        bl      recv_message

        ldr     r1, =msg_end
        ldr     r0, =msg_buf
        str     r0, [r1]

        b       finish

finish:
        pop     {r0-r2,pc}

##############################################################################

# Args: r0 - ptr to message (zero-terminated)
#       r1 - ptr to nick (zero-terminated)

recv_message:
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
