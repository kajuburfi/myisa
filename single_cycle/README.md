# Single Cycle implementation of `myisa`

In this directory is the source code for the SystemVerilog HDL of a single-cycle implementation of `myisa`.
The circuit diagram for the processor is given here.

![Processor diagram](./myisa_single_cycle.png)

I will not intensively document this portion, since the main one would be the pipelined processor for `myisa`.
It is to be noted, however, that the instructions `mul` and `div` have not been implemented.
They are commented out in the ALU, since they are not directly synthesizable. 

## Running

I use [`iverilog`](https://github.com/steveicarus/iverilog) and [`gtkwave`](https://github.com/gtkwave/gtkwave) for viewing the waveforms. 

Assembling(`pwd` is this directory),
```sh
$ gcc -o assembler assembler.c
$ ./assembler <input asm file>
$ ./assembler fibo.asm
```

You will now get a `output.bin` file in this directory. This is overwritten everytime you assemble.
Now, to run the processor,

```sh
$ iverilog -g2012 -o proc src/* # You should now get a file `proc`
$ vvp proc # You should now get a file `dump.vcd`
$ gtkwave dump.vcd
```
Note the `-g2012` flag. This is necessary since I use the 2012 version of SystemVerilog.
