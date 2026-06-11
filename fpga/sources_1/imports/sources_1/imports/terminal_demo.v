`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/30/2021 03:02:43 PM
// Design Name: 
// Module Name: terminal_demo
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module terminal_demo(
    input clk, reset_n,
    
    // Receiver port
    input rd_uart,      // left push button
    output rx_empty,    // LED0
    input rx,           
    
    // Transmitter port
    input [7:0] w_data, // SW0 -> SW7
    input wr_uart,      // right push button
    output tx_full,     // LED1
    output tx,
    
    // Sseg signals
    output [6:0] sseg,
    output [0:7] AN,
    output DP
    );
    
    // Push buttons debouncers/synchronizers
    button read_uart(
        .clk(clk),
        .reset_n(reset_n),
        .noisy(rd_uart),
        .debounced(),
        .p_edge(rd_uart_pedge),
        .n_edge(),
        ._edge()
    );
    
    button write_uart(
        .clk(clk),
        .reset_n(reset_n),
        .noisy(wr_uart),
        .debounced(),
        .p_edge(wr_uart_pedge),
        .n_edge(),
        ._edge()
    );
        
    // UART Driver
    wire [7:0] r_data;
    uart #(.DBIT(8), .SB_TICK(16)) uart_driver(
        .clk(clk),
        .reset_n(reset_n),
        .r_data(r_data),
        .rd_uart(fifo1_rd_en),
        .rx_empty(rx_empty),
        .rx(rx),
        .w_data(w_data),
        .wr_uart(wr_uart_pedge),
        .tx_full(tx_full),
        .tx(tx),
        .TIMER_FINAL_VALUE(11'd650) // baud rate = 9600 bps
    );

    
    wire fifo1_rd_en, fifo2_wr_en, fifo2_rd_en;
    wire [15:0] fifo2_din;
    FIFO_ByteToWord_Controller u_fifo_bytetoword_controller(
        .clk(clk),
        .rst(~reset_n),
        .rd_btn(rd_uart_pedge),
    
        // FIFO1 (Xilinx IP)
        .fifo1_dout(r_data),
        .fifo1_empty(rx_empty),
        .fifo1_rd_en(fifo1_rd_en),
    
        // FIFO2 (Xilinx IP)
        .fifo2_wr_en(fifo2_wr_en),
        .fifo2_full(1'b0),
        .fifo2_din(fifo2_din),
        .fifo2_empty(out_empty),
        .fifo2_rd_en(fifo2_rd_en)
    );


    wire [15:0] out_data;
    wire out_empty;
    fifo_generator_1 out_FIFO(
        .clk(clk),          // input wire clk
        .srst(~reset_n),    // input wire srst
        .din(fifo2_din),      // input wire [15 : 0] din
        .wr_en(fifo2_wr_en),  // input wire wr_en
        .rd_en(fifo2_rd_en),    // input wire rd_en
        .dout(out_data),      // output wire [15 : 0] dout
        .full(),            // output wire full
        .empty(out_empty)    // output wire empty
    );
    
    // Seven-Segment Driver
    sseg_driver u_sseg_driver(
        .clk(clk),
        .reset_n(reset_n),
        .I0({1'b1, w_data[3: 0], 1'b0}),
        .I1({1'b1, w_data[7: 4], 1'b0}),
        .I2(6'd0),
        .I3(6'd0),
        .I4({~out_empty, out_data[3: 0], 1'b0}),
        .I5({~out_empty, out_data[7: 4], 1'b0}),
        .I6({~out_empty, out_data[11:8], 1'b0}),
        .I7({~out_empty, out_data[15:12], 1'b0}),
        .AN(AN),
        .sseg(sseg),
        .DP(DP)
    );
    
endmodule

/*
module dff
  #(parameter WIDTH = 16,
    parameter RST_VAL = 0)
  (
    input clk, en, rst,
    input [WIDTH-1:0] d,
    output [WIDTH-1:0] q
  );
  reg q;
  always @(posedge clk, posedge rst) begin
    if (rst)
      q <= RST_VAL;
    else if (en)
      q <= d;
  end
endmodule

module dmux
  #(parameter WIDTH = 16)
  (
    input [WIDTH-1:0] inp,
    input s,
    output reg [WIDTH-1:0] y0, y1
  );
  always @(*) begin
    if (s==0)
      y0 = inp;
    else if (s==1)
      y1 = inp;
    else
      y0 = inp;
  end
endmodule
*/
