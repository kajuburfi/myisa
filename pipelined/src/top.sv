module top(
  input logic clk, rst,
  output logic [2:0] ctrl_syscall
);
  // Internal wires
  logic [15:0] pcm1, pcm2, pcnext, pcnew,  
          Hrr2, srcA, srcB, wd, rr1out;
  logic [3:0] a1_in;
  // Internal wires with stage presence
  logic [15:0] pcF, instrF, immF, aluout;
  logic [15:0] pcD, instrD, immD, rr1D, rr2D;
  logic [15:0] pcE, instrE, immE, rr1E, rr2E, aluoutE, Hrr1E;
  logic [15:0] instrM, Hrr1M, aluoutM, rmM;
  logic [15:0] instrW, aluoutW, rmW;
  // Ctrl signals
  logic is_b;
  logic is_immF, is_rweF, is_mweF, is_rdF, is_memoutF, is_pc_regF;
  logic [2:0] ctrl_aluF, ctrl_syscallF;
  logic [1:0] ctrl_bF;
  logic is_immD, is_rweD, is_mweD, is_rdD, is_memoutD, is_pc_regD;
  logic [2:0] ctrl_aluD, ctrl_syscallD;
  logic [1:0] ctrl_bD;
  logic is_immE, is_rweE, is_mweE, is_memoutE, is_pc_regE;
  logic [2:0] ctrl_aluE, ctrl_syscallE;
  logic is_rweM, is_mweM, is_memoutM;
  logic [2:0] ctrl_syscallM;
  logic is_rweW, is_memoutW;
  logic [2:0] ctrl_syscallW; // This is ctrl_syscall output signal
  // Hazard signals
  logic [1:0] fwdaE, fwdbE;
  logic flushE, stallF, stallD;
  logic fwdrr1D;

  // Modules and their connections.

  // Hazard unit
  hazard_unit hazard_unit(
  // fwd
  is_rweM, is_rweW,
  (is_rdD ? instrE[11:8] : instrE[3:0]), instrE[7:4], instrM[11:8], instrW[11:8],
  fwdaE, fwdbE,
  // stall
  is_memoutE,
  instrE[11:8], (is_rdD?instrD[11:8]:instrD[3:0]), instrD[7:4],
  flushE, stallF, stallD,
  // ctrl
  instrD[15:12],
  fwdrr1D
  );
   
  sub1 sub1_1(pcm1, pcm2);
  mux mux_pc1(pcm1, pcm2, is_immF, pcnext);
  mux mux_pc2(pcnext, rr2D, is_b, pcnew);
  dff #(16, 16'd255) dff_pc(clk, ~stallF, rst, pcnew, pcF);
  sub1 sub1_2(pcF, pcm1);

  imem imem_module(pcF, pcm1, instrF, immF);
  ctrl_unit ctrl_unit_module(instrF, is_immF, is_rweF, is_mweF, is_memoutF, is_rdF, is_pc_regF, ctrl_syscallF, ctrl_aluF, ctrl_bF);

  fd_pr fd_pr(clk, ~stallD,
    is_immF, is_rdF, is_rweF, is_pc_regF, is_mweF, is_memoutF,
    ctrl_aluF, ctrl_syscallF,
    ctrl_bF,
    pcF, instrF, immF,
    is_immD, is_rdD, is_rweD, is_pc_regD, is_mweD, is_memoutD,
    ctrl_aluD, ctrl_syscallD,
    ctrl_bD,
    pcD, instrD, immD
  );

  mux #(4) mux_instr(instrD[3:0], instrD[11:8], is_rdD, a1_in);

  regfile rf_module(clk, is_rweW, a1_in, instrD[7:4], instrW[11:8], wd, rr1out, rr2D);

  mux mux_after_rf(rr1out, aluoutM, fwdrr1D, rr1D);

  b_box b_box_module(rr1D[1:0], ctrl_bD, is_b);

  de_pr de_pr(clk, flushE,
  is_immD, is_rweD, is_pc_regD, is_mweD, is_memoutD,
  ctrl_aluD, ctrl_syscallD,
  pcD, rr2D, rr1D, immD, instrD,
  is_immE, is_rweE, is_pc_regE, is_mweE, is_memoutE,
  ctrl_aluE, ctrl_syscallE,
  pcE, rr2E, rr1E, immE, instrE
  );

  mux3 mux_rr2E_wd_aluoutM(rr2E, wd, aluoutM, fwdaE, Hrr2);
  mux3 mux_rr1E_wd_aluoutM(rr1E, wd, aluoutM, fwdbE, Hrr1E);

  mux mux_pc_rr2(Hrr2, pcE, is_pc_regE, srcA);
  mux mux_imm_rr1(Hrr1E, immE, is_immE, srcB);
  
  alu alu_module(srcA, srcB, ctrl_aluE, aluoutE);

  em_pr em_pr(clk,
  is_rweE, is_mweE, is_memoutE,
  ctrl_syscallE,
  aluoutE, Hrr1E, instrE,
  is_rweM, is_mweM, is_memoutM,
  ctrl_syscallM,
  aluoutM, Hrr1M, instrM
  );

  dmem dmem_module(clk, is_mweM, aluoutM, Hrr1M, rmM);

  mw_pr mw_pr(clk,
  is_rweM, is_memoutM,
  ctrl_syscallM,
  aluoutM, rmM, instrM,
  is_rweW, is_memoutW,
  ctrl_syscall,
  aluoutW, rmW, instrW
  );

  mux mux_aluout_rm(aluoutW, rmW, is_memoutW, wd);
endmodule
