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
      2'b11: y = d0;
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

module encoder_8_3(
  input logic [7:0] inp,
  output logic [2:0] y
);
  assign y[2] = inp[4] | inp[5] | inp[6] | inp[7];
  assign y[1] = inp[2] | inp[3] | inp[6] | inp[7];
  assign y[0] = inp[1] | inp[3] | inp[5] | inp[7];
endmodule

module pwm_generator (
    input clk,          // FPGA clock (e.g., 50 MHz)
    input reset,        // Active-high reset
    input [7:0] duty,   // 8-bit duty cycle (0-255 = 0%-100%)
    output reg pwm_out  // PWM output signal
);

reg [7:0] counter;      // 8-bit counter (0-255)

always @(posedge clk or posedge reset) begin
    if (reset) begin
        counter <= 0;
        pwm_out <= 0;
    end
    else begin
        counter <= counter + 1;
        pwm_out <= (counter < duty) ? 1 : 0;  // Compare & set PWM
    end
end
endmodule

// pm => programming memory
module fsm_pgm_mem(
  input clk, rst,
  input logic pgm_mem_pedge,
  input logic [15:0] out_data,
  output logic pm_btnU, pm_btnC, pm_btnEXT
);
  logic pm_active = 0;
  logic pm_done = 0;
  always_ff @(posedge clk) begin
    if (!pm_active && pgm_mem_pedge) begin
      pm_active <= 1;
    end
    if (pm_done) begin
      pm_active <= 0;
    end

    if (&out_data)
      pm_done <= 1;
    else
      pm_done <= 0;
  end

  logic q0, q1;
  dff #(1, 0) fsm_dffQ1(clk, 1'b1, (pm_active && ~&out_data), (pgm_mem_pedge & (q1 ^ q0)), q1);
  dff #(1, 0) fsm_dffQ0(clk, 1'b1, (pm_active && ~&out_data), (pgm_mem_pedge & (~q0 | (q1&q0))), q0);

  always_comb begin
    case ({q1, q0})
      default: {pm_btnU, pm_btnC, pm_btnEXT} = 3'b000;
      2'b00: {pm_btnU, pm_btnC, pm_btnEXT} = 3'b000;
      2'b01: {pm_btnU, pm_btnC, pm_btnEXT} = 3'b100;
      2'b10: {pm_btnU, pm_btnC, pm_btnEXT} = 3'b010;
      2'b11: {pm_btnU, pm_btnC, pm_btnEXT} = 3'b001;
    endcase
  end
endmodule
