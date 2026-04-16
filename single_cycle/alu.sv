module alu
  (
    input logic [15:0] srca,
    input logic [15:0] srcb,
    input logic [2:0] ctrl_alu,
    output logic [15:0] aluout,
  );
  // TODO: add mul and div
  always_comb begin
    case (ctrl_alu)
      3'b000: aluout = srca + srcb; //add
      3'b001: aluout = srca - srcb; //sub
      3'b010: aluout = ~(srca & srcb); //nand
      // 3'b001: aluout = srca | srcb; //or
      3'b011: aluout = srca > srcb ? 16'h0002 : 16'h0000; //sgt - for branch bgt
      // 3'b011: aluout = srca ^ srcb; //xor
      // 3'b100: aluout = ~(srca | srcb); //nor
      default: aluout = {16{1'bx}}; // Set X value otherwise
    endcase
  end
  
endmodule

