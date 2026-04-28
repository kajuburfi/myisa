module dmem(
  input logic clk, mwe,
  input logic [15:0] a, wd,
  output logic [15:0] rm
);
  logic [15:0] temp; // useless anyway
  mainMemory dmem(clk, mwe, a, wd, a, 16'b0, rm, temp);
endmodule

