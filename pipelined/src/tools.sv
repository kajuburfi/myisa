module dff
  #(parameter WIDTH = 16,
    parameter RST_VAL = 0)
  (
    input logic clk, en, rst,
    input logic [WIDTH-1:0] d,
    output logic [WIDTH-1:0] q
  );
  always_ff @(posedge clk, posedge rst) begin
    if (rst)
      q <= RST_VAL;
    else if (en)
      q <= d;
  end
endmodule


module mux
  #(parameter WIDTH = 16)
  (
    input logic [WIDTH-1:0] d0, d1,
    input logic s,
    output logic [WIDTH-1:0] y
  );
  // assign y = s ? d1 : d0;
  always_comb begin
    if (s==0)
      y = d0;
    else if (s==1)
      y = d1;
    else
      y = d0;
  end
endmodule

module mux3
  #(parameter WIDTH = 16)
  (
    input logic [WIDTH-1:0] d0, d1, d2,
    input logic [1:0] s,
    output logic [WIDTH-1:0] y
  );
  // assign y = s ? d1 : d0;
  always_comb begin
    case(s)
      2'b00: y = d0;
      2'b01: y = d1;
      2'b10: y = d2;
    endcase
  end
endmodule

module dmux
  #(parameter WIDTH = 16)
  (
    input logic [WIDTH-1:0] inp,
    input logic s,
    output logic [WIDTH-1:0] y0, y1
  );
  always_comb begin
    if (s==0)
      y0 = inp;
    else if (s==1)
      y1 = inp;
    else
      y0 = inp;
  end
endmodule


module sub1
  #(parameter WIDTH = 16)
  (
    input logic [WIDTH-1:0] srcA,
    output logic [WIDTH-1:0] out
  );
  assign out = $unsigned(srcA - 16'h0001);
endmodule

module b_box
  (
    input logic [1:0] flg, ctrl_b,
    output logic is_b
  );
  assign is_b = (ctrl_b[0] & ctrl_b[1]) | (ctrl_b[0] & flg[0]) | (ctrl_b[1] & flg[1]);
endmodule
