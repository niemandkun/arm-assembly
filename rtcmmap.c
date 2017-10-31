#include <stdio.h>
#include <assert.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <fcntl.h>

#define rtc_base_addr 0x01f00000

volatile unsigned* databuf;

volatile unsigned* do_mmap(int memfd) {
    return (volatile unsigned*)
            mmap(NULL, 4096, PROT_READ | PROT_WRITE,
                    MAP_SHARED, memfd, rtc_base_addr);
}
