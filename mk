#!/bin/bash

if [[ ! $GCC ]]; then
    GCCFLAGS="-O0"
    GCC=arm-linux-gnueabihf-gcc\ $GCCFLAGS
fi

if [[ ! $AS ]]; then
    AS=arm-linux-gnueabihf-as
fi

if [[ ! $LD ]]; then
    LD=arm-linux-gnueabihf-ld
fi

if [[ $# -ne 1 && $# -ne 2 ]]; then
    echo 'Usage: make [-h] [BUILDER] TARGET'
fi

if [[ $1 == "-h" ]]; then
    echo 'Usage: make [-h] [BUILDER] TARGET'
    echo
    echo 'A script to build single ASM or C source file.'
    echo
    echo 'Arguments:'
    echo '    -h        - show this help message and exit.'
    echo '    TARGET    - source file to build.'
    echo '    BUILDER   - tool to use when building TARGET,'
    echo '                possible values: "gcc", "c", "s", "as", "asm".'
    echo
    echo 'If BUILDER is "gcc" or "c", then gcc will be used to compile TARGET. If BUILDER'
    echo 'is "asm", "as" or "s", then as and ld will be used.'
    echo
    echo 'If no builder provided, target extension will be used to determine builder.'
    echo 'Files ends with .c will be compiled with gcc, and files ends with .s will be'
    echo 'assemblied with as and linked with ld.'
    echo
fi

function make_gcc {
    $GCC $1
}

function make_asm {
    $AS $1 -o a.o
    if [[ -e a.o ]]; then
        $LD a.o -o a.out
        rm a.o
    fi
}

if [[ $1 == gcc ]]; then
    make_gcc $2
fi

if [[ $1 == as || $1 == asm ]]; then
    make_asm $2
fi

FILE_EXT=${1##*.}

if [[ $FILE_EXT == c ]]; then
    make_gcc $1
fi

if [[ $FILE_EXT == s ]]; then
    make_asm $1
fi

if [[ -e a.out ]]; then
    chmod +x a.out
fi
