##############################################################################

.text

##############################################################################

clear_screen:
        push    {r0-r1,lr}

        ldr     r0, =esc_clear
        mov     r1, #2
        bl      do_escape

        pop     {r0-r1,pc}

##############################################################################

# args: r0 - row, r1 - column

set_cursor_position:
        push    {r0-r3,lr}

        mov     r2, r0      @ row
        mov     r3, r1      @ column

        ldr     r0, =esc_voffset
        mov     r1, r2
        add     r1, #1
        bl      do_escape

        ldr     r0, =esc_hoffset
        mov     r1, r3
        add     r1, #1
        bl      do_escape

        pop     {r0-r3,pc}

##############################################################################

# args: r0 - command offset, r1 - argument

do_escape:
        push    {r0-r2,r7,lr}

        mov     r2, r0      @ command
        mov     r7, r1      @ argument

        ldr     r0, =escape
        ldr     r1, =print_buf

        bl      strcpy      @ copy escape characters
        add     r1, r0

        mov     r0, r7

        bl      prntdbuf    @ copy argument
        add     r1, r0

        mov     r0, r2      @ copy command

        bl      strcpy
        add     r1, r0

        ldr     r0, =print_buf

        sub     r2, r1, r0  @ length

        mov     r1, r0
        mov     r0, #1
        mov     r7, #4
        svc     #0  @ write(STDOUT, print_buf, r2)

        pop     {r0-r2,r7,pc}


##############################################################################

.data

##############################################################################

escape:         .asciz "\033["

esc_voffset:    .asciz "d"
esc_hoffset:    .asciz "G"
esc_clear:      .asciz "J"

##############################################################################

.bss

##############################################################################

print_buf:      .space 1000

##############################################################################

# End of file
