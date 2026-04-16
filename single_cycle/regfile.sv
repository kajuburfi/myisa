module regfile(
  input logic clk,
  input logic rwe,
  input logic [3:0] a1, a2, a3,
  input logic [15:0] wd,
  output logic [15:0] rr1, rr2
);
  logic [15:0] rf[15:0];
  // three ported register file
  // read two ports combinationally
  // write third port on rising edge of clk
  // register 0 hardwired to 0
  // note: for pipelined processor, write third port
  // on falling edge of clk
  always_ff @(posedge clk) begin
    if (rwe) rf[a3] <= wd;
  end
  assign rr1 = (a1 != 0) ? rf[ra1] : 0;
  assign rr2 = (a2 != 0) ? rf[ra2] : 0;
endmodule

