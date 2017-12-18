##############################################################################

.globl main

.include "libstring.s"

.include "libprint.s"

.include "libkbd.s"

.include "libescape.s"

.include "libmem.s"

.include "libtime.s"

.include "libuart.s"

.include "model.s"

.include "controller.s"

.include "extensions.s"

.include "tui.s"

##############################################################################

.text

##############################################################################

main:
        push    {lr}

        mov     r11, r0
        mov     r12, r1

        bl      libmem_init
        tst     r0, r0
        bne     exit

        bl      libtime_init
        tst     r0, r0
        bne     exit

        mov     r0, r11
        mov     r1, r12

        bl      libuart_init
        tst     r0, r0
        bne     exit

        bl      ext_init

        bl      canon
        bl      model_init
        bl      controller_init

        bl      main_loop

        bl      cleanup
        bl      nocanon

        b       exit

exit:
        pop     {pc}

##############################################################################
