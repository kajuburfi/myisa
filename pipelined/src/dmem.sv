module dmem(
  input logic clk, mwe,
  input logic [15:0] a, wd,
  output logic [15:0] rm
);
  logic [15:0] RAM[63:0];
  assign rm = RAM[a[15:0]]; // word aligned
  always_ff @(posedge clk) begin
    if (mwe) RAM[a[15:0]] <= wd;
  end
endmodule

