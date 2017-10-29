.global _start

.include "libpring.s"

.text

_start:

        ldr     r0, [r1, #4]
        bl      readfile

exit:
        eor     r0, r0
        mov     r7, #1
        svc     #0

# args: r0 - ptr to file path

readfile:
        push    {r1, lr}

        eor     r1, r1
        mov     r7, #5
        svc     #0

after_open:
        tst     r0, r0
        ble     1f

        ldr     r1, =buffer
        ldr     r2, bufflen
        mov     r7, #3
        svc     #0

1:
        pop     {r1, pc}

.bss

bufflen = 1000000
buffer: .space bufflen
