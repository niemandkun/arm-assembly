.global _start
.text
_start:
    mov     r7, #4
    mov     r0, #1
    ldr     r1, =messaga
    ldr     r2, =lmessaga
    svc     #0
    mov     r7, #1
    svc     #0

.data
messaga: .ascii "Hello from ARM!\n"
lmessaga = . - messaga
