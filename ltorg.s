.global _start

.text

_start:
    mov     r0, #1
    ldr     r1, messaddr
    mov     r2, #len
    mov     r7, #4
    swi     0x0

    mov     r0, #0
    mov     r7, #1
    swi     0x0
messaddr:   .long str

.ltorg

.data

str:
    .ascii "Hello from asm!\n"
len = . - str
