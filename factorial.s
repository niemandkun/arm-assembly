.global main

.text

main:
    push    {lr}
    mov     r0, #12
    mov     r1, r0
    bl      factorial_iter
    mov     r2, r0
    ldr     r0, =str
    bl      printf
    pop     {pc}


factorial:
    push    {r1, lr}
    tst     r0, r0
    bne     call

    mov     r0, #1
    pop     {r1, pc}

call:
    mov     r1, r0
    sub     r0, r0, #1
    bl      factorial
    mul     r0, r1, r0
    pop     {r1, pc}


factorial_iter:
    push    {r1, lr}
    mov     r1, r0
    mov     r0, #1

cycle:
    tst     r1, r1
    pople   {r1, pc}
    mul     r0, r1, r0
    sub     r1, #1
    b       cycle

.data

str: .ascii "%u! = %u\n"
str1: .word 0x0
