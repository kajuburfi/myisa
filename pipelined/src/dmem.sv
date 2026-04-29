module dmem(
  input logic clk, mwe,
  input logic [15:0] a, wd,
  output logic [15:0] rm
);
  logic [15:0] temp1, temp2; // useless anyway
  mainMemory dmem(clk, mwe, a, wd, 16'b0, 16'b0, temp1, temp2, rm);
endmodule

