module hazard_unit(
  // ctrl signals
  input logic is_rweM, is_rweW,
  //wires
  input logic [3:0] a1_in, a2_in, instrM, instrW,
  //output signals
  output logic [1:0] fwdaE, fwdbE
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
endmodule
