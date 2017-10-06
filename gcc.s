.global main
.text
main:
    push    {lr}
    mov     r7, #4
    mov     r0, #1
    ldr     r1, =messaga
    ldr     r2, =lmessaga
    svc     #0
    pop     {pc}

.data
messaga: .ascii "Hello from ARM!\n"
lmessaga = . - messaga
