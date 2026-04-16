module dff
  #(parameter WIDTH = 16)
  (
    input logic clk, rst,
    input logic [WIDTH-1:0] d,
    output logic [WIDTH-1:0] q
  );
  always_ff @(posedge clk, posedge rst) begin
    if (rst) q <= 0;
    else q <= d;
  end
endmodule


module mux
  #(parameter WIDTH = 16)
  (
    input logic [WIDTH-1:0] d0, d1,
    input logic s,
    output logic [WIDTH-1:0] y
  );
  assign y = s ? d1 : d0;
endmodule


module sub1
  #(parameter WIDTH = 16)
  (
    input logic [WIDTH-1:0] srcA,
    output logic [WIDTH-1:0] out
  );
  assign out = srcA - 1;
endmodule

module b_box
  (
    input logic [1:0] flg, ctrl_b,
    output logic [1:0] is_b
  );
  assign is_b = (ctrl_b[0] & ctrl_b[1]) | (ctrl_b[0] & flg[0]) | (ctrl_b[1] & flg[1]);
endmodule
