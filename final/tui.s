##############################################################################

.text

##############################################################################

MESSAGE_BOX_HEIGHT = 7

UPDATE_INTERVAL = 0x00010000

##############################################################################

main_loop:
        push    {lr}

        ldr     r12, =UPDATE_INTERVAL

main_loop_start:

        subs    r12, #1
        bne     check_input

render:
        bl      clear_screen
        bl      get_window_size
        bl      draw_window
        bl      draw_history
        bl      draw_input

        ldr     r12, =UPDATE_INTERVAL

check_input:
        bl      check_uart_input

        bl      kbdhit
        tst     r0, r0
        beq     main_loop_start

handle_input:
        mov     r2, r0
        ldr     r1, =key_buf
        mov     r0, #0
        mov     r7, #3
        svc     #0  @ read(STDIN, key_buf, r0);

        ldr     r1, =key_buf
        ldrb    r2, [r1]

        cmp     r2, #0x03 @ ^C
        beq     main_loop_finish

        bl      handle_tui_input

        b       main_loop_start

main_loop_finish:
        pop     {pc}

##############################################################################

cleanup:
        push    {lr}

        bl      reset_terminal

        eor     r0, r0
        eor     r1, r1
        bl      set_cursor_position

        pop     {pc}

##############################################################################

draw_window:
        push    {r0-r3,r7,lr}

        ldr     r0, =ws_row
        ldrh    r0, [r0]

        sub     r0, r0, #MESSAGE_BOX_HEIGHT
        sub     r0, r0, #1
        eor     r1, r1

        bl      set_cursor_position     @ set_cursor_position(ws_row - 7, 0)

        ldr     r3, =ws_col
        ldrh    r3, [r3]

        mov     r0, #1
        ldr     r1, =win_divider
        mov     r2, #1
        mov     r7, #4
1:
        svc     #0  @ write(STDOUT, win_divider, 1);
        subs    r3, r3, #1
        bne     1b

        pop     {r0-r3,r7,pc}

##############################################################################

draw_input:
        push    {r0-r3,r7,lr}

        ldr     r0, =ws_row
        ldrh    r0, [r0]

        sub     r0, r0, #MESSAGE_BOX_HEIGHT @ r0 = textbox top
        eor     r1, r1
        bl      set_cursor_position

#        ldr     r0, =input_buf
#        ldr     r1, =msg_end

        ldr     r0, =in_net_buf
        ldr     r1, =in_net_buf_end

        ldr     r1, [r1]
        mov     r2, #MESSAGE_BOX_HEIGHT
        ldr     r3, =ws_col
        ldrh    r3, [r3]
        bl      lineskiplast

        sub     r2, r1, r0
        mov     r1, r0

        mov     r0, #1
        mov     r7, #4

        svc     #0  @ write(STDOUT, input, r2);

        pop     {r0-r3,r7,pc}

##############################################################################

draw_history:
        push    {r0-r12,lr}

        ldr     r10, =ws_row
        ldrh    r10, [r10]

        sub     r10, r10, #MESSAGE_BOX_HEIGHT
        sub     r10, r10, #1        @ r10 = textbox height

        eor     r11, r11            @ r11 = textbox top

        ldr     r0, =hist_buf
        ldr     r1, =hist_end
        ldr     r1, [r1]
        ldr     r2, =hist_scroll
        ldr     r2, [r2]
        ldr     r3, =ws_col
        ldrh    r3, [r3]
        bl      lineskiplast

        mov     r9, r0              @ r9 = ptr to text end

        ldr     r0, =hist_buf
        mov     r1, r9
        mov     r2, r10
        ldr     r3, =ws_col
        ldrh    r3, [r3]
        bl      lineskiplast

        mov     r8, r0              @ r8 = ptr to text start

        sub     r2, r9, r8          @ r2 = length of text

        mov     r0, r11
        eor     r1, r1
        bl      set_cursor_position

        mov     r0, #1
        mov     r1, r8
        mov     r7, #4
        svc     #0

        pop     {r0-r12,pc}

##############################################################################

get_window_size:
        push    {r0-r2,lr}

TIOCGWINSZ = 0x5413

        mov     r0, #0
        ldr     r1, =TIOCGWINSZ
        ldr     r2, =winsize

        bl      ioctl

        pop     {r0-r2,pc}

##############################################################################

.data

##############################################################################

win_divider:    .ascii "="

##############################################################################

.bss

##############################################################################

winsize:

ws_row:         .space 2
ws_col:         .space 2
ws_xpixel:      .space 2
ws_ypixel:      .space 2

key_buf:        .space 10

##############################################################################
