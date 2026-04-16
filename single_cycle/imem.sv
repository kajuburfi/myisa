module imem(
  input logic [15:0] a1, a2,
  output logic [15:0] ri1, ri2
);
  // NOTE: Here, the book mentions that we need to use RAM[63:0], but this gives a warning/error.
  // Hence, we use RAM[0:17].
  // Reference: https://stackoverflow.com/questions/66824196/icarus-verilog-warning-readmemh-standard-inconsistency-following-1364-2005
  logic [15:0] RAM[0:17];
  initial begin 
    $readmemh("instr.dat", RAM);
  end
  assign ri1 = RAM[a1]; // word aligned
  assign ri2 = RAM[a2];
endmodule

