module hazard_unit(
  // RAW (fwd)
  // ctrl signals
  input logic is_rweM, is_rweW,
  //wires
  input logic [3:0] a1_in, a2_in, instrM_dst, instrW_dst,
  //output signals
  output logic [1:0] fwdaE, fwdbE,
  // STALL
  input logic is_memoutE,
  input logic [3:0] instrE_dst, instrD_s1, instrD_s2,
  output logic flushE, stallF, stallD,
  // CTRL
  input logic ctrl_b_not_zero, is_memoutM, is_rweE,
  input logic [3:0] instrD_op,
  output logic fwdrr1D
);
  // For RAW Hazards ONLY - Simple forwarding
  always_comb begin
    // For srcA
    if ((a2_in != 15) && (a2_in == instrM_dst) && is_rweM)
      fwdaE = 2'b10;
    else if ((a2_in != 15) && (a2_in == instrW_dst) && is_rweW)
      fwdaE = 2'b01;
    else
      fwdaE = 2'b00;
    // For srcB
    if ((a1_in != 15) && (a1_in == instrM_dst) && is_rweM)
      fwdbE = 2'b10;
    else if ((a1_in != 15) && (a1_in == instrW_dst) && is_rweW)
      fwdbE = 2'b01;
    else
      fwdbE = 2'b00;
  end

  // Stalling for lw instruction
  always_comb begin
    if ( (((instrD_s1 == instrE_dst) || (instrD_s2 == instrE_dst)) && is_memoutE)
      || ((ctrl_b_not_zero && is_rweE && (instrE_dst == instrD_s1 || instrE_dst == instrD_s2))
         || (ctrl_b_not_zero && is_memoutM && (instrM_dst == instrD_s1 || instrM_dst == instrD_s2)))
    ) begin
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
    if ((instrD_s1!=15) && (instrD_s1 == instrM_dst) && is_rweM && (instrD_op == 10 || instrD_op == 11 || instrD_op == 12)) begin
      fwdrr1D = 1; 
    end else begin
      fwdrr1D = 0;
    end
  end
endmodule
