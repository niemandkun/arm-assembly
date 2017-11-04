.global _start

.include "libprint.s"

.text

_start:
NITER           = 1

        bl      do_mmap_rtc_mem
        ldr     r12, =NITER
1:
        bl      printtime
        subs    r12, #1
        bgt     1b

        bl      do_close_rtc_mem

exit:
        eor     r0, r0
        mov     r7, #1
        svc     #0  @exit(0)


do_mmap_rtc_mem:
        # args: none
        # returns: address of allocation start
        push    {r1-r7,lr}

O_RDWR          = 0x0002
O_DSYNC         = 0x1000

open_flags      = O_RDWR | O_DSYNC

        ldr     r0, =memfile
        ldr     r1, =open_flags
        mov     r7, #5
        svc     #0  @open(memfile)

        tst     r0, r0
        blt     exit

        ldr     r1, =filedesc
        str     r0, [r1]

PROT_READ       = 0x0001
PROT_WRITE      = 0x0002
MAP_SHARED      = 0x0001

mmap_prot       = PROT_READ | PROT_WRITE
mmap_flags      = MAP_SHARED
rtc_base        = 0x1f00

        mov     r4, r0
        eor     r0, r0
        mov     r1, #1
        ldr     r2, =mmap_prot
        ldr     r3, =mmap_flags
        ldr     r5, =rtc_base
        mov     r7, #192
        svc     #0  @mmap2(0, 1, mmap_prot, mmap_flags, 0, rtc_base_addr)

        pop     {r1-r7,pc}


do_close_rtc_mem:
        push    {r0,r7,lr}
        ldr     r0, =filedesc
        ldr     r0, [r0]
        mov     r7, #6
        svc     #0  @close(filedesc)
        pop     {r0,r7,pc}


printtime:
        # args: r0 - address of allocation start
        push    {r0-r2,r7,r12,lr}

        mov     r12, r0

        ldr     r0, [r12, #16]
        ldr     r1, =printbuf
        bl      prntxbuf
        prnts   printbuf, printbuf_len

        ldr     r0, [r12, #20]
        ldr     r1, =printbuf
        bl      prntxbuf
        prnts   printbuf, printbuf_len

        pop     {r0-r2,r7,r12,pc}

.bss

filedesc:       .space 4


.data
printbuf:       .space 8
                .ascii "\n"

printbuf_len    = . - printbuf

memfile:        .asciz "/dev/mem"
