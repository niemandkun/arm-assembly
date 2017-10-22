.global _start

.include "libprint.s"

BAD_LUCK = -1

.text

_start:
    argc    .req r4
    argv    .req r5
    num     .req r8
    rad     .req r9

    ldr     argc, [sp]
    add     argv, sp, #4
    cmp     argc, #3
    bne     exit

    ldr     r0, [argv, #4]
    bl      parseint
    cmp     r0, #BAD_LUCK
    beq     error
    mov     num, r0

    ldr     r0, [argv, #8]
    bl      parseint
    cmp     r0, #0
    ble     error
    mov     rad, r0

    mov     r0, num
    bl      prntd

    prnts   in_base, in_base_len

    mov     r0, rad
    bl      prntd

    prnts   is, is_len

    mov     r0, num
    mov     r1, rad
    bl      prnt

    prnts   newline, newline_len
    b       exit

error:
    prnts   error_msg, error_msg_len

exit:
    mov     r7, #1
    eor     r0, r0
    svc     #0

.data

newline:    .byte 0xA
newline_len = . - newline

in_base:    .ascii " in base "
in_base_len = . - in_base

is:         .ascii " is "
is_len = . - is

error_msg:  .ascii "Invalid input\n"
error_msg_len = . - error_msg
