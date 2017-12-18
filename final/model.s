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

        pop     {pc}

##############################################################################

.data

##############################################################################

input:          .ascii "> "

default_nick:   .asciz "Аркадий"

system_nick:    .asciz "System"

error_msg_send: .asciz "Error occured: message was not delivered."

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
