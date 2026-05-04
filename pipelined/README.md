# Pipelined `myisa` processor

In this directory is the source code for the SystemVerilog HDL of a pipelined implementation of `myisa`.
The circuit diagram for the processor is given below.

> Note that `mul` and `div` operations are not implemented, since they are not directly
> synthesizable. I plan on implementing it using adders and subtractors directly.

## Diagrams

#### Basic Pipeline(no hazards fix)
![Basic pipeline](./diagrams/myisa_pipelined_basic.png)

#### Pipeline with forwarding
![Pipeline with forwarding](./diagrams/myisa_pipelined_fwd.png)

#### Pipeline with forwarding and stalls
![Pipeline with fwd and stalls](./diagrams/myisa_pipelined_stall.png)

#### Pipeline with forwarding, stalls and control hazard fix
![Pipeline with ctrl fix](./diagrams/myisa_pipelined_ctrl_hazard_fix.png)

## Execution

I use [`iverilog`](https://github.com/steveicarus/iverilog) and [`gtkwave`](https://github.com/gtkwave/gtkwave) for viewing the waveforms. 

Assembling(`pwd` is this directory),
```sh
$ gcc -o assembler assembler.c
$ ./assembler <input asm file>
$ ./assembler ../tests/fibo.asm # example
```

You will now get a `mem.hex` file in this directory. This is overwritten everytime you assemble.
It will contain a bunch of zeroes(256KiB in fact), except towards the end, where the program instructions are stored.
The instructions are stored as in [`ARCH.md`](../ARCH.md), starting from address `0xFFFF`, and moving upwards.
Note that for some assembly test files(example: [`largest_num.asm`](../tests/largest_num.asm)), we need to update the memory file before running it.

Now, to run the processor,

```sh
$ iverilog -g2012 -o proc src/alu.sv src/ctrl_unit.sv src/dmem.sv src/hazard_unit.sv src/imem.sv src/mainmem.sv src/pipeline_regs.sv src/regfile.sv src/tb_proc.sv src/tools.sv src/top.sv # This is basically everything except the cache file.
$ vvp proc # The processor has processed, and you should now get a file `dump.vcd`
$ gtkwave dump.vcd
```

Note the `-g2012` flag. This is necessary since I use the 2012 version of SystemVerilog.
The clock runs at 1 cycle/10 units of time. You can see how many clock cycles the program took to complete
by running `gtkwave`. It prints the start time(always `15`, since the reset falls back after 15 units) and the end time.

## Advanced Microarchitectural Concepts implemented

As of writing this README, nothing much has been implemented. 

- [X] **Early branch resolution**(done in the Decode Stage of the pipeline), leading to a reduced number of stalls(only one per branch).
- [ ] **A simple branch predictor**
- [ ] **Multilevel cache hierarchy**: L1, L2 and main memory.
- [ ] **Dedicated Multiplication and Division units**: To be run alongside the ALU in the Execute Stage.

and others.
