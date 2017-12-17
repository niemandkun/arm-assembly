##############################################################################

.globl main

.include "libprint.s"

.include "libstring.s"

.include "libkbd.s"

.include "libescape.s"

.include "libmem.s"

.include "libtime.s"

.include "model.s"

.include "controller.s"

.include "tui.s"

##############################################################################

.text

##############################################################################

main:
        push    {lr}

        bl      libmem_init
        tst     r0, r0
        bne     libmem_error

        bl      libtime_init

        bl      canon
        bl      model_init

        bl      main_loop

        bl      cleanup
        bl      nocanon

        b       exit

libmem_error:
        ldr     r0, =error_msg
        bl      prntz

exit:
        pop     {pc}

##############################################################################
