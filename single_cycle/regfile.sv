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
  // register zero(which is 15) hardwired to 0
  // note: for pipelined processor, write third port
  // on falling edge of clk
  always_ff @(posedge clk) begin
    if (rwe) rf[a3] <= wd;
  end
  assign rr1 = (a1 != 15) ? rf[a1] : 0;
  assign rr2 = (a2 != 15) ? rf[a2] : 0;
endmodule

