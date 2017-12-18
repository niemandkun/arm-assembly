##############################################################################

.globl main

.include "libprint.s"

.include "libstring.s"

.include "libkbd.s"

.include "libescape.s"

.include "libmem.s"

.include "libtime.s"

.include "libuart.s"

.include "model.s"

.include "controller.s"

.include "tui.s"

##############################################################################

.text

##############################################################################

main:
        push    {lr}

        push    {r0,r1}

        bl      libmem_init
        tst     r0, r0
        bne     exit

        bl      libtime_init
        tst     r0, r0
        bne     exit

        pop     {r0,r1}

        bl      libuart_init
        tst     r0, r0
        bne     exit

        bl      canon
        bl      model_init

        bl      main_loop

        bl      cleanup
        bl      nocanon

        b       exit

exit:
        pop     {pc}

##############################################################################
