.global main

.include "libprint.s"

.text

main:
    push    {lr}

    ldr     r0, =memfile
    ldr     r1, =flags
    mov     r7, #5
    svc     #0

    tst     r0, r0
    blt     1f

    mov     r11, r0
    push    {r0}

    bl      do_mmap
    mov     r10, r0

    pop     {r0}

    ldr     r0, [r10, #16]
    ldr     r1, =printbuf
    bl      prntxbuf
    prnts   printbuf, printbuf_len

    ldr     r0, [r10, #20]
    ldr     r1, =printbuf
    bl      prntxbuf
    prnts   printbuf, printbuf_len

    mov     r0, r11
    mov     r7, #6
    svc     #0

1:
    pop     {pc}

.data

flags = 00000002 | 00010000

memfile:    .asciz "/dev/mem"

printbuf:   .space 8
            .ascii "\n"
printbuf_len = . - printbuf
