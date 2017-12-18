##############################################################################

.text

##############################################################################

libmem_init:
        # args: none
        # returns: 1 if error, 0 if OK
        push    {r1-r7,lr}

O_RDWR          = 0x0002
O_DSYNC         = 0x1000
OPEN_FLAGS      = O_RDWR | O_DSYNC

        ldr     r0, =memfile
        ldr     r1, =OPEN_FLAGS
        mov     r7, #5
        svc     #0  @open(memfile)

        tst     r0, r0
        blt     libmem_error

        ldr     r1, =memfile_handle
        str     r0, [r1]
        eor     r0, r0
        b       libmem_exit

libmem_error:
        ldr     r0, =libmem_error_msg
        bl      prntz
        mvn     r0, #1

libmem_exit:
        pop     {r1-r7,pc}

##############################################################################

libmem_cleanup:
        push    {r0,r7,lr}
        ldr     r0, =memfile_handle
        ldr     r0, [r0]
        mov     r7, #6
        svc     #0  @close(memfile_handle)
        pop     {r0,r7,pc}

##############################################################################

do_mmap_mem:
        # args: r0 - offset of memory to be mmaped
        # returns: r0 - address of allocation start
        push    {r1-r7,lr}

        mov     r5, r0

PROT_READ       = 0x0001
PROT_WRITE      = 0x0002
MAP_SHARED      = 0x0001

MMAP_PROT       = PROT_READ | PROT_WRITE
MMAP_FLAGS      = MAP_SHARED

        eor     r0, r0
        mov     r1, #4096
        mov     r2, #MMAP_PROT
        mov     r3, #MMAP_FLAGS
        ldr     r4, =memfile_handle
        ldr     r4, [r4]
        mov     r7, #192
        svc     #0  @mmap2(0, 1, MMAP_PROT, MMAP_FLAGS, filedesc, base_addr)

        pop     {r1-r7,pc}

##############################################################################

.data

##############################################################################

memfile:        .asciz "/dev/mem"

libmem_error_msg:
                .asciz "[Error] Cannot open /dev/mem, aborting.\n"

##############################################################################

.bss

##############################################################################

memfile_handle: .space 4

##############################################################################
