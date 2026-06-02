`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/28/2026 06:57:18 PM
// Design Name: 
// Module Name: button
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

// Inspired from: https://github.com/aseddin/ece_3300/tree/main/M10%20Sequential%20Circiut%20Timing/Source


module button(
    input clk, reset_n,
    input noisy,
    output debounced,
    output p_edge, n_edge, _edge
    );
    
    synchronizer #(.STAGES(2))SYNCH0(
        .clk(clk),
        .reset_n(reset_n),
        .D(noisy),
        .Q(synch_noisy)
    );
    
    debouncer_delayed DD0(
        .clk(clk),
        .reset_n(reset_n),
        .noisy(synch_noisy),
        .debounced(debounced)
    );
    
    edge_detector ED0(
        .clk(clk),
        .reset_n(reset_n),
        .level(debounced),
        .p_edge(p_edge),
        .n_edge(n_edge),
        ._edge(_edge)
    );
    
endmodule

module debouncer_delayed_fsm(
    input clk, reset_n,
    input noisy, timer_done,
    output timer_reset, debounced
    );
    
    reg [1:0] state_reg, state_next;
    parameter s0 = 0, s1 = 1, s2 = 2, s3 = 3;
    
    // Sequential state register
    always @(posedge clk, negedge reset_n)
    begin
        if (~reset_n)
            state_reg <= 0;
        else
            state_reg <= state_next;
    end
    
    // Next state logic
    always @(*)
    begin
        state_next = state_reg;
        case(state_reg)
            s0: if (~noisy)
                    state_next = s0;
                else if (noisy)
                    state_next = s1;
            s1: if (~noisy)
                    state_next = s0;
                else if (noisy & ~timer_done)
                    state_next = s1;
                else if (noisy & timer_done)
                    state_next = s2;
            s2: if (~noisy)
                    state_next = s3;
                else if (noisy)
                    state_next = s2;
            s3: if (noisy)
                    state_next = s2;
                else if (~noisy & ~timer_done)
                    state_next = s3;
                else if (~noisy & timer_done)
                    state_next = s0;
            default: state_next = s0;                                             
        endcase
    end
    
    // output logic
    assign timer_reset = (state_reg == s0) | (state_reg == s2);
    assign debounced = (state_reg == s2) | (state_reg == s3);
    
endmodule

module debouncer_delayed(
    input clk, reset_n,
    input noisy,
    output debounced
    );
    
    wire timer_done, timer_reset;
    
    debouncer_delayed_fsm FSM0(
        .clk(clk),
        .reset_n(reset_n),
        .noisy(noisy),
        .timer_done(timer_done),
        .timer_reset(timer_reset),
        .debounced(debounced)
    );
    
    // 20 ms timer
    timer_parameter #(.FINAL_VALUE(1_999_999)) T0(
        .clk(clk),
        .reset_n(~timer_reset),
        .enable(~timer_reset),
        .done(timer_done)
    );
endmodule

module synchronizer
    #(parameter STAGES = 2)(
    input clk, reset_n,
    input D,
    output Q
    );
    
    reg [STAGES - 1:0] Q_reg;
    always @(posedge clk, negedge reset_n)
    begin
        if (~reset_n)
            Q_reg <= 'b0;
        else
            Q_reg <= {D, Q_reg[STAGES - 1:1]};
    end
    
    assign Q = Q_reg[0];
endmodule

module timer_parameter
    #(parameter FINAL_VALUE = 255)(
    input clk,
    input reset_n,
    input enable,
    //    output [BITS - 1:0] Q, // we don't care about the value of the counter
    output done
    );
    
    localparam BITS = $clog2(FINAL_VALUE);
    
    reg [BITS - 1:0] Q_reg, Q_next;
    
    always @(posedge clk, negedge reset_n)
    begin
        if (~reset_n)
            Q_reg <= 'b0;
        else if(enable)
            Q_reg <= Q_next;
        else
            Q_reg <= Q_reg;
    end
    
    // Next state logic
    assign done = Q_reg == FINAL_VALUE;

    always @(*)
        Q_next = done? 'b0: Q_reg + 1;
    
    
endmodule

module edge_detector(
    input clk, reset_n,
    input level,
    output p_edge, n_edge, _edge
    );
    
    // Edge detector with Mealy outputs
    reg state_reg, state_next;
    parameter s0 = 0, s1 = 1;
    
    // Sequential state registers
    always @(posedge clk, negedge reset_n)
    begin
        if (~reset_n)
            state_reg <= s0;
        else
            state_reg <= state_next;
    end
    
    // Next state logic
    always @(*)
    begin
        case(state_reg)
            s0: if (level)
                    state_next = s1;
                else
                    state_next = s0;
            s1: if (level)
                    state_next = s1;
                else
                    state_next = s0;
            default: state_next = s0;                
        endcase
    end
    
    // Output logic
    assign p_edge = (state_reg == s0) & level;
    assign n_edge = (state_reg == s1) & ~level;
    assign _edge = p_edge | n_edge;
    
endmodule

module udl_counter
    #(parameter BITS = 4)(
    input clk,
    input reset_n,
    input enable,
    input up, //when asserted the counter is up counter; otherwise, it is a down counter
    input load,
    input [BITS - 1:0] D,
    output [BITS - 1:0] Q
    );
    
    reg [BITS - 1:0] Q_reg, Q_next;

    initial begin
        Q_next = 12'hFFF;
        Q_reg = 12'hFFF;
    end
    
    always @(posedge clk, negedge reset_n)
    begin
        if (~reset_n)
            Q_reg <= 'b0;
        else if(enable)
            Q_reg <= Q_next;
        else
            Q_reg <= Q_reg;
    end
    
    // Next state logic
    always @(Q_reg, up, load, D)
    begin
        Q_next = Q_reg;
        casex({load,up})
            2'b00: Q_next = Q_reg - 1;
            2'b01: Q_next = Q_reg + 1;
            2'b1x: Q_next = D;
            default: Q_next = Q_reg;
        endcase
        
    end
    
    // Output logic
    assign Q = Q_reg;
endmodule
