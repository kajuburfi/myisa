# Single Cycle implementation of `myisa`

In this directory is the source code for the SystemVerilog HDL of a single-cycle implementation of `myisa`.
The circuit diagram for the processor is given here.

![Processor diagram](./img.jpg)

> Note: A couple of modifications to the processor drawn here has been done, namely:
> - Added a bunch of combinatorial logic to access the `pc` register
> - Added some logic in the [`ctrl_unit`](./src/ctrl_unit.sv) to stop execution when reaching `0xFFFF`.

I will not intensively document this portion, since the main one would be the pipelined processor for `myisa`.
