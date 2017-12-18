##############################################################################

.text

##############################################################################

EXT_FILE_TRANSFER = 0x01

O_RDWR = 0x02

O_READ = 0x00

##############################################################################

ext_init:
        push    {r0,r1}
        ldr     r0, =other_extensions
        eor     r1, r1
        strb    r1, [r0]
        pop     {r0,r1}
        mov     pc, lr

##############################################################################

# Send extensions vector over uart.

ext_advertise:
        push    {r0,r1,lr}

        ldr     r0, =cmd_ext
        ldr     r1, =out_net_buf
        bl      strcpy
        add     r1, r0

        ldr     r0, =my_extensions
        bl      strcpy
        add     r1, r0

        bl      write_checksum
        bl      send_buffer

        pop     {r0,r1,pc}

##############################################################################

# Args: r0 - ptr to extensions vector (zero terminated)

ext_save:
        push    {r0,r1,lr}

        ldr     r1, =other_extensions
        bl      strcpy

        pop     {r0,r1,pc}

##############################################################################

# Args: r0 - extension ID

# Returns: r0 = 0 if has extension, r0 = 1 otherwise

has_ext:
        push    {r1,r2,lr}

        ldr     r1, =other_extensions

1: @ begin iterating over other extensions:
        ldrb    r2, [r1], #1
        tst     r2, r2
        beq     2f

        cmp     r2, r0
        beq     3f

        b       1b

2: @ has no extension:
        mov     r0, #1
        b       4f

3: @ has extension:
        eor     r0, r0

4: @ finish:
        pop     {r1,r2,pc}

##############################################################################

# Args: r0 - ptr to filename start (zero terminated)

ext_start_send_file:
        push    {r0-r2,r11,lr}

        mov     r11, r0

        bl      do_open_file
        tst     r0, r0
        bge     2f

1: @ cannot open file:
        ldr     r0, =error_cant_open
        ldr     r1, =out_net_buf
        bl      strcpy
        add     r1, r1, r0

        mov     r0, r11
        bl      strcpy
        add     r1, r1, r0

        ldr     r0, =out_net_buf
        ldr     r1, =system_nick
        bl      add_msg_to_hist

        b       3f

2: @ open file ok:
        mov     r2, r0

        ldr     r0, =EXT_FILE_TRANSFER
        bl      has_ext
        tst     r0, r0

        mov     r0, r2

        bleq    send_file_ext
        blne    send_file_compat

        bl      do_close_file

        ldr     r1, =out_net_buf
        ldr     r0, =msg_sent_file
        bl      strcpy
        add     r1, r1, r0

        mov     r0, r11
        bl      strcpy
        add     r1, r1, r0

        ldr     r0, =out_net_buf
        ldr     r1, =self_nick
        bl      add_msg_to_hist

3: @ finish:
        pop     {r0-r2,r12,pc}

##############################################################################

# Args: r0 - path to file.

do_open_file:
        push    {r1,r7,lr}
        ldr     r1, =O_READ
        mov     r7, #5
        svc     #0 @ open(r0, O_RDWR);
        pop     {r1,r7,pc}

##############################################################################

# Args: r0 - file handle

send_file_compat:
        push    {r0-r2,r7,r12,lr}

        mov     r12, r0

        ldr     r1, =out_net_buf
        ldr     r0, =cmd_msg
        bl      strcpy
        add     r1, r1, r0

        mov     r0, r12
        ldr     r2, =in_net_buf
        sub     r2, r2, r1
        sub     r2, r2, #1
        mov     r7, #3
        svc     #0  @ read(r0, r1, in_net_buf - r1 - 1);

read_ok:
        add     r1, r1, r0

        mov     r0, #0x0A
        strb    r0, [r1], #1

        bl      write_checksum
        bl      send_buffer
        bl      wait_ok

        pop     {r0-r2,r7,r12,pc}

##############################################################################

# Args: r0 - file handle

send_file_ext:
        mov     pc, lr

##############################################################################

# Args: r0 - file handle

do_close_file:
        push    {r7,lr}
        mov     r7, #6
        svc     #0
        pop     {r7,pc}

##############################################################################

.data

##############################################################################

cmd_ext:        .asciz "/ext "
cmd_send:       .asciz "/send "

my_extensions:  @ .byte EXT_FILE_TRANSFER
                .byte 0

msg_sent_file:  .asciz "Sent file "

error_cant_open:
                .asciz "Cannot open file: "

##############################################################################

.bss

##############################################################################

other_extensions:
                .space 4

##############################################################################
