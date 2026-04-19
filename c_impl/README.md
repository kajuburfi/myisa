# `myisa`: C Implementation
A C implementation of My ISA.

## Why?

This is a small project taken upon by me to play around with implementing an ISA.
For simplicity, I have written this in C, and it is barely 300 lines of code.
It is a very non-standard way of an ISA, and thus is quite interesting(although it was made _interesting_ for different purposes).
Refer the [Architecture](../ARCH.md) for more information regarding how the ISA is made.

## How to use

The `assembler.c` assembles your `myisa` assembly into the binary file `output.bin`. You can run this using the `computer.c`, which simulates
a computer on your computer, and you can run it by passing `output.bin` to this program. Example:
```sh
# Compilation
gcc assembler.c -o assembler
gcc computer.c -o computer

./assembler test.asm # This makes `output.bin`
./computer output.bin # This runs the program.
  
```

As it is, the C assembler will not output anything, but just make the file.
The C computer(on running) will print out the program data and where it is saved as:
```sh
# Memory addr        Binary value
     FFFF                50F0
     FFFE                000F
     FFFD                51F0
     FFFC                0001
     FFFB                42F1
     FFFA                1190
     FFF9                0000
     FFF8                1290
     FFF7                0001
     FFF6                9900
     FFF5                58A0
     FFF4                FFF3
     FFF3                C800
     FFF2                4312
     FFF1                1390
     FFF0                0002
     FFEF                5120
     FFEE                0000
     FFED                5230
     FFEC                0000
     FFEB                5990
     FFEA                0001
     FFE9                57A0
     FFE8                000E
     FFE7                A700
     FFE6                FFFF
```

After this, it prints out the instruction that it is executing, and then the registers after it exectues, and then the
first 20 memory addresses(all in hexadecimal). This can be edited through the C program.

If there are any errors in your `myisa` program, the assembler is NOT smart, and will just try to assemble it as is, leading to segfaults or infinite loops
when you are running the program using `computer`. Refer the `tests/` directory for some examples of `myisa` programs(well commented).
