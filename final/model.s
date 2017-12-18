##############################################################################

.text

##############################################################################

model_init:
        push    {lr}

        ldr     r0, =input
        ldrh    r0, [r0]
        ldr     r1, =input_buf
        strh    r0, [r1]

        ldr     r0, =msg_buf
        ldr     r1, =msg_end
        str     r0, [r1]

        ldr     r0, =hist_buf
        ldr     r1, =hist_end
        str     r0, [r1]

        eor     r0, r0
        ldr     r1, =msg_scroll
        str     r0, [r1]

        ldr     r1, =hist_scroll
        str     r0, [r1]

        ldr     r0, =default_nick
        ldr     r1, =self_nick
        bl      strcpy

        ldr     r0, =default_nick
        ldr     r1, =other_nick
        bl      strcpy

        eor     r0, r0
        ldr     r1, =online_flag
        str     r0, [r1]

        ldr     r0, =welcome_msg
        ldr     r1, =system_nick
        bl      add_msg_to_hist

        pop     {pc}

##############################################################################

.data

##############################################################################

input:          .ascii "> "

default_nick:   .asciz "Аркадий"

system_nick:    .asciz "Narrator"

error_msg_send: .asciz "Error occured: message was not delivered."

welcome_msg:    .ascii "Welcome to the Rites, Wanderer. "
                .ascii "What is thy name today?\r\n\r\n"
                .asciz "(Use command `/name [NAME]` to set the name)."

offline_msg:    .ascii "The Rites have ended and no one left by the fire.\r\n"
                .asciz "Until the next Rites, Wanderer."

online_msg:     .ascii "Suddenly, somebody has appeared "
                .asciz "in the front of the fire."

nick_msg:       .asciz "The stars aligned for thou to meet "

nick_chg_msg:   .asciz "And shall thou find the the glory at the Rites, "

template:       .ascii "1 Lorem ipsum dolor sit amet.\r\n"
                .ascii "2 Lorem ipsum dolor sit amet.\r\n"
                .ascii "3 Lorem ipsum dolor sit amet.\r\n"
                .ascii "4 Lorem ipsum dolor sit amet.\r\n"
                .ascii "5 Lorem ipsum dolor sit amet.\r\n"
                .ascii "6 Lorem ipsum dolor sit amet.\r\n"
                .ascii "7 Lorem ipsum dolor sit amet.\r\n"
                .ascii "8 Lorem ipsum dolor sit amet.\r\n"
                .ascii "9 Lorem ipsum dolor sit amet.\r\n"
                .asciz "10 Lorem ipsum dolor sit amet."

##############################################################################

.bss 

##############################################################################

online_flag:    .space 4

msg_scroll:     .space 4
msg_end:        .space 4
input_buf:      .space 2
msg_buf:        .space 1000000

hist_scroll:    .space 4
hist_end:       .space 4
hist_buf:       .space 1000000

self_nick:      .space 256
other_nick:     .space 256

##############################################################################
