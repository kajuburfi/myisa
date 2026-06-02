# Pipelined `myisa` processor on an FPGA!

This directory houses the source code written to put `myisa` on an FPGA.
Board Used: [Nexys A7](https://digilent.com/reference/_media/reference/programmable-logic/nexys-a7/nexys-a7_rm.pdf).
FPGA Chip in the Nexys A7 is the Artix 7.

The processor design is more or less the same. The `top` file was remade from scratch, since in the previous
(pipelined) version, I assumed a simulation and wrote the testbench accordingly.
Now, we have full access to the memory, and can look through and edit the memory using the hardware on the Nexys A7 board.
I use the Buttons, switches and the 8 seven-segment LED displays to scroll through and edit the memory.

All the programs that could be run on the simulation can also be done here. 

More to be added.
