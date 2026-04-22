module hazard_unit(
  // RAW (fwd)
  // ctrl signals
  input logic is_rweM, is_rweW,
  //wires
  input logic [3:0] a1_in, a2_in, instrM, instrW,
  //output signals
  output logic [1:0] fwdaE, fwdbE,
  // STALL
  input logic is_memoutE,
  input logic [3:0] instrE_dst, instrD_s1, instrD_s2,
  output logic flushE, stallF, stallD,
  // CTRL
  output logic fwdrr1D
);
  // For RAW Hazards ONLY - Simple forwarding
  always_comb begin
    // For srcA
    if ((a2_in != 15) && (a2_in == instrM) && is_rweM)
      fwdaE = 2'b10;
    else if ((a2_in != 15) && (a2_in == instrW) && is_rweW)
      fwdaE = 2'b01;
    else
      fwdaE = 2'b00;
    // For srcB
    if ((a1_in != 15) && (a1_in == instrM) && is_rweM)
      fwdbE = 2'b10;
    else if ((a1_in != 15) && (a1_in == instrW) && is_rweW)
      fwdbE = 2'b01;
    else
      fwdbE = 2'b00;
  end

  // Stalling for lw instruction
  always_comb begin
    if ( ((instrD_s1 == instrE_dst) || (instrD_s2 == instrE_dst)) && is_memoutE ) begin
      stallF = 1;
      stallD = 1;
      flushE = 1;
    end else begin
      stallF = 0;
      stallD = 0;
      flushE = 0;
    end
  end

  always_comb begin
    if ((instrD_s1!=15) && (instrD_s1 == instrM) && is_rweM) begin
      fwdrr1D = 1; 
    end else begin
      fwdrr1D = 0;
    end
  end
endmodule
