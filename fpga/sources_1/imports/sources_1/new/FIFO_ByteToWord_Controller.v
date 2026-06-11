`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/05/2026 12:53:46 PM
// Design Name: 
// Module Name: FIFO_ByteToWord_Controller
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

// Generated with the help of AI

module FIFO_ByteToWord_Controller (
    input clk,
    input rst,
    input rd_btn,
    
    // FIFO1 (Xilinx IP)
    input [7:0] fifo1_dout,
    input fifo1_empty,
    output fifo1_rd_en,
    
    // FIFO2 (Xilinx IP)
    output fifo2_wr_en,
    input fifo2_full,
    output [15:0] fifo2_din,
    input fifo2_empty,
    output fifo2_rd_en
);

    // ===========================
    // Internal Signals
    // ===========================
    wire [7:0] byte_out;
    wire byte_valid;
    
    wire [15:0] word_out;
    wire word_valid;
    wire word_ready;
    
    // ===========================
    // FIFO1_Reader Logic
    // ===========================
    localparam FIFO1_IDLE = 2'b00;
    localparam FIFO1_WAIT = 2'b11;
    localparam FIFO1_READ_LOW = 2'b01;
    localparam FIFO1_READ_HIGH = 2'b10;
    
    reg [1:0] fifo1_state;
    
    always @(posedge clk) begin
        if (rst) begin
            fifo1_state <= FIFO1_IDLE;
        end else begin
            case (fifo1_state)
                FIFO1_IDLE: begin
                    if (~fifo1_empty) begin
                        fifo1_state <= FIFO1_READ_LOW;
                    end
                end

                FIFO1_WAIT: begin
                    fifo1_state <= FIFO1_READ_LOW;
                end
                
                FIFO1_READ_LOW: begin
                    fifo1_state <= FIFO1_READ_HIGH;
                end
                
                FIFO1_READ_HIGH: begin
                    if (~fifo1_empty) begin
                        fifo1_state <= FIFO1_IDLE;
                    end
                end
            endcase
        end
    end
    
    assign fifo1_rd_en = (fifo1_state == FIFO1_READ_LOW) | (fifo1_state == FIFO1_READ_HIGH);
    
    reg [7:0] fifo1_byte_out;
    reg fifo1_byte_valid;
    
    always @(posedge clk) begin
        if (rst) begin
            fifo1_byte_valid <= 1'b0;
        end else begin
            fifo1_byte_valid <= 1'b0;
            
            case (fifo1_state)
                FIFO1_READ_LOW: begin
                    fifo1_byte_out <= fifo1_dout;
                    fifo1_byte_valid <= 1'b1;
                end
                
                FIFO1_READ_HIGH: begin
                    if (~fifo1_empty) begin
                        fifo1_byte_out <= fifo1_dout;
                        fifo1_byte_valid <= 1'b1;
                    end
                end
            endcase
        end
    end
    
    assign byte_out = fifo1_byte_out;
    assign byte_valid = fifo1_byte_valid;
    
    // ===========================
    // ByteToWordConverter Logic
    // ===========================
    localparam CONV_WAIT_LOW = 1'b0;
    localparam CONV_WAIT_HIGH = 1'b1;
    
    reg conv_state;
    reg [7:0] low_byte;
    reg conv_word_valid;
    reg [15:0] conv_word_out;
    
    always @(posedge clk) begin
        if (rst) begin
            conv_state <= CONV_WAIT_LOW;
            conv_word_valid <= 1'b0;
        end else begin
            conv_word_valid <= 1'b0;
            
            case (conv_state)
                CONV_WAIT_LOW: begin
                    if (byte_valid) begin
                        low_byte <= byte_out;
                        conv_state <= CONV_WAIT_HIGH;
                    end
                end
                
                CONV_WAIT_HIGH: begin
                    if (byte_valid) begin
                        conv_word_out <= {low_byte, byte_out};
                        conv_word_valid <= 1'b1;
                        
                        if (word_ready) begin
                            conv_state <= CONV_WAIT_LOW;
                        end
                    end
                end
            endcase
        end
    end
    
    assign word_out = conv_word_out;
    assign word_valid = conv_word_valid;
    
    // ===========================
    // FIFO2_Writer Logic
    // ===========================
    
    // Write to FIFO2
    assign word_ready = ~fifo2_full;
    
    reg fifo2_wr_en_reg;
    
    always @(posedge clk) begin
        if (rst) begin
            fifo2_wr_en_reg <= 1'b0;
        end else begin
            fifo2_wr_en_reg <= word_valid & ~fifo2_full;
        end
    end
    
    assign fifo2_wr_en = fifo2_wr_en_reg;
    assign fifo2_din = word_out;
    
    // Read from FIFO2
    reg fifo2_rd_en_reg;
    
    always @(posedge clk) begin
        if (rst) begin
            fifo2_rd_en_reg <= 1'b0;
        end else begin
            fifo2_rd_en_reg <= rd_btn & ~fifo2_empty;
        end
    end
    
    assign fifo2_rd_en = fifo2_rd_en_reg;

endmodule
