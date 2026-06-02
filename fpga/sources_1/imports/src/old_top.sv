`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/27/2026 11:33:52 PM
// Design Name: 
// Module Name: adder
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

module top2(
    input logic clk,
    input logic [15:0] sw, // Switches
    input logic btnU, btnD, btnC, btnR, btnL,
    output logic [7:0] sseg, // segments and "dp" - decimal point
    output logic [7:0] an, // anodes for the 8 digits
    output logic [15:0] LED
    );
    
    logic [6:0] seg_pattern;
    logic [15:0] sum_out [256];
    logic [15:0] mem_sel;
        
    // Slow clock type stuff:
    logic [15:0] cnt_out = 0;
    logic [2:0] digit_sel;
    logic [3:0] curr;
    
    always @(posedge clk) 
        cnt_out <= cnt_out + 1;
    assign digit_sel = cnt_out[15:13];

    // Scrolling up and down the memory 
    logic is_btnU, is_btnD, is_btnR, is_btnL;
    button u_debounceU(.clk(clk), .reset_n(1'b1), .noisy(btnU), .debounced(), .p_edge(is_btnU), .n_edge(), ._edge());
    button u_debounceD(.clk(clk), .reset_n(1'b1), .noisy(btnD), .debounced(), .p_edge(is_btnD), .n_edge(), ._edge());
    button u_debounceR(.clk(clk), .reset_n(1'b1), .noisy(btnR), .debounced(is_btnR), .p_edge(), .n_edge(), ._edge());
    button u_debounceL(.clk(clk), .reset_n(1'b1), .noisy(btnL), .debounced(is_btnL), .p_edge(), .n_edge(), ._edge());

    udl_counter #(.BITS(16)) DEBOUNCED_BUTTON_COUNTER (
        .clk(clk),
        .reset_n(1'b1),
        .enable(is_btnD || is_btnU || is_load),
        .up((is_btnD) ? 1'b1 : 1'b0),
        .load(is_load),
        .D(sw),
        .Q(mem_sel)
    );

    logic is_load = 0;
    // buttons related
    always @(posedge clk) begin
        if (btnC) begin
            sum_out[mem_sel] <= sw;
        end

        if (btnL) begin
            is_load <= 1;
        end else begin
            is_load <= 0;
        end
    end
    
    // Quick changing of digit
    always_comb begin
        case (digit_sel)
            3'b000: begin
                curr = (~|sw || btnR) ? mem_sel[3:0] : sw[3:0];
                an = 8'b1110_1111;
                sseg = (btnR || is_load || ~|sw) ? {1'b0, seg_pattern} : {1'b1, seg_pattern};
            end
            3'b001: begin
                curr = (~|sw || btnR) ? mem_sel[7:4] : sw[7:4];
                //an = 8'b1111_1101;
                an = 8'b1101_1111;
                sseg = (btnR || is_load || ~|sw) ? {1'b0, seg_pattern} : {1'b1, seg_pattern};
            end
            3'b010: begin
                curr = (~|sw || btnR) ? mem_sel[11:8] : sw[11:8];
                //an = 8'b1111_1011;
                an = 8'b1011_1111;
                sseg = (btnR || is_load || ~|sw) ? {1'b0, seg_pattern} : {1'b1, seg_pattern};
            end
            3'b011: begin
                curr = (~|sw || btnR) ? mem_sel[15:12] : sw[15:12];
                //an = 8'b1111_0111;
                an = 8'b0111_1111;
                sseg = (btnR || is_load || ~|sw) ? {1'b0, seg_pattern} : {1'b1, seg_pattern};
            end
            3'b100: begin
                curr = sum_out[mem_sel][3:0];
                an = 8'b1111_1110;
                sseg = (is_load) ? {1'b0, seg_pattern} : {1'b1, seg_pattern};
            end
            3'b101: begin
                curr = sum_out[mem_sel][7:4];
                //an = 8'b1111_1101;
                an = 8'b1111_1101;
                sseg = (is_load) ? {1'b0, seg_pattern} : {1'b1, seg_pattern};
            end
            3'b110: begin
                curr = sum_out[mem_sel][11:8];
                //an = 8'b1111_1011;
                an = 8'b1111_1011;
                sseg = (is_load) ? {1'b0, seg_pattern} : {1'b1, seg_pattern};
            end
            3'b111: begin
                curr = sum_out[mem_sel][15:12];
                //an = 8'b1111_0111;
                an = 8'b1111_0111;
                sseg = (is_load) ? {1'b0, seg_pattern} : {1'b1, seg_pattern};
            end
            default: begin
                curr = 4'h0;
                an = 8'b1111_1111;
            end
        endcase
    end
    
    // Convert to segment display
    hex_to_7seg u_hex_to_7seg(
        .hex(curr),
        .seg(seg_pattern)
    );
    
    // Map the pattern to the digits, keep DP off(leading 1)
    // assign sseg = (btnR) ? {1'b0, seg_pattern} : {1'b1, seg_pattern};
    
    assign LED = sw;
endmodule
