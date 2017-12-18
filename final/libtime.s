##############################################################################

.text

##############################################################################

RTC_BASE_ADDRESS = 0x1f00

##############################################################################

libtime_init:
        push    {r1,lr}
        ldr     r0, =RTC_BASE_ADDRESS
        bl      do_mmap_mem
        ldr     r1, =rtc_mem_base
        str     r0, [r1]
        eor     r0, r0
        pop     {r1,pc}

##############################################################################

# Args: r1 - offset in memory.
# Returns: r0 - length of the written data.

print_time:
        push    {r1-r4,lr}

        mov     r4, r1

TIME_MASK       = 0xff

        ldr     r2, =TIME_MASK

        ldr     r0, =rtc_mem_base
        ldr     r0, [r0]

        ldr     r3, [r0, #20]
        rev     r3, r3

        ror     r3, r3, #8
        and     r0, r3, r2
        bl      prntdbuf
        add     r1, r0

        mov     r0, #0x3A
        strb    r0, [r1], #1

        ror     r3, r3, #8
        and     r0, r3, r2
        bl      prntdbuf
        add     r1, r0

        mov     r0, #0x3A
        strb    r0, [r1], #1

        ror     r3, r3, #8
        and     r0, r3, r2
        bl      prntdbuf
        add     r1, r0

        sub     r0, r1, r4

        pop     {r1-r4,pc}

##############################################################################

.bss

##############################################################################

rtc_mem_base:   .space 4

##############################################################################
