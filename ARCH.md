# Instruction Set Architecture

This is a (WIP) basic ISA inspired by MIPS, RISC-V, IAS computer architectures.

## Memory and Storage

This is a word addressable storage type, with 2 bytes per word.
It has 16 bits addresses, which leads us to have 128 kB of data storage.
The memory tape would go from `0x0000` to `0xFFFF`.
We also have 16 registers, each being 16 bits.

We do not implement a stack or heap.
There are two (not clearly split) segments of this 128kB.
The program section, and the data section.
Every program that is loaded is stored from `0xFFFF` and grows downwards.
All the data that can be stored starts from `0x0000` and grows upwards.
Following this, we don't implement a clear distinction between the two sections.

<!-- Insert image here -->

It is made with the intention to give complete control over the 128kB to the programmer.
The programmer can thus make programs that overwrite the program itself, as it can
access any memory location. All the registers are writable, including vital ones like
PC(program counter), or even the `zero` register!!

## Registers and Encoding

We have 16 registers, each having a word of space(2 bytes).
There are a couple pre-defined registers:

- `PC`: Program Counter; Starts at `0xFFFF` and moves downwards.
- `IBR`: Immediate Buffer Register; This is a special register implemented for this specific
  ISA due to some concerns with immediates.
- `hi`: Used in multiplication and division.
- `lo`: Used in multiplication and division.
- `flg`: Used to maintain equal-to and greater-than flags(in 1 bit each).
- `zero`: The zero register.

The other 10 registers, `r0`, `r1`, ..., `r9`, are available to the programmer.

The way the instructions are encoded are as follows. Each instruction has a 4 bit opcode,
and can take upto 3 operands. For the _R-type_(register) instructions, they are stored as such.

<!-- Insert img --> 

For immediates, a little more involvement comes into picture.

> I wanted to be able to access all possible data sections of the memory tape, hence this
> idea was born.

Whenever immediates are included, they are placed on a separate line. A common instruction like `addi`
would look like this:
```
addi r1, r2
49

# OR
addi r1, r2
0x48E2
```

As you can see, the third operand(the immediate) is on a separate line. This is because of
multiple reasons. Each line in the assembly code is mapped to one word in the program section of the
memory tape. If we have to cut off any part of the address, we can't access a major part of the memory tape.
On the other hand, we have 16 bits to store some data, why would we want to waste some of it(in the
data section)? Some ISAs have cleverly overcome this problem with `lui`(load upper immediate) and the like,
but this would increase our instruction set, and we had a hard limit of 16 instructions.

Hence, immediate instructions would be stored as:

<!-- Insert img --> 

## Instruction Set

Here is the instruction set implemented. 

| Opcode | Instruction | Explanation |
| :----: | :---------- | :---------- |
| `0000` | `lw r1, r2`<br>`imm` | Loads the word `imm(r2)` into `r1`. |
| `0001` | `sw r1, r2`<br>`imm` | Stores the value of the register `r1` into `imm(r2)`. |
| `0010` | `nand r1, r2, r3` | Stores the value of `NAND(r2, r3)` into `r1` |
| `0011` | `nandi r1, r2`<br>`imm` | Stores the value of `NAND(r2, imm)` into `r1` |
| `0100` | `add r1, r2, r3` | `r1 = r2 + r3` |
| `0101` | `addi r1, r2`<br>`imm` | `r1 = r2 + imm` |
| `0110` | `sub r1, r2, r3` | `r1 = r2 - r3` |
| `0111` | `mul r1, r2` | Stores the most significant 16 bits of `r1*r2` into `hi` and the least significant bits into `lo`|
| `1000` | `div r1, r2` | `hi = r1/r2` (integer division), `lo = r1%r2`(remainder) |
| `1001` | `cmp r1, r2` | Sets the `flg` register with the required value. |
| `1010` | `b r1` | Sets the `pc` to whatever value is in `r1` |
| `1011` | `beq r1` | Sets `pc = r1` if `flg.eq == 1` |
| `1100` | `bgt r1` | Sets `pc = r1` if `flg.gt == 1` |

