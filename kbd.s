.global main

.text

main:
        push    {lr}

        bl      canon

1:
        bl      kbdhit
        tst     r0, r0
        beq     1b

        bl      getchar

        bl      putchar

        bl      nocanon

        pop     {pc}
