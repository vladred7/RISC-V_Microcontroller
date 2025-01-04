//######################################## Header ########################################
//# Author: Vlad Rosu                                                                    #
//# Description: Hazards unit used for pipeline CPU                                      #
//########################################################################################

module cpu_hazard_unit (
   //    Input ports definition
   input          pc_src,
   input  [4:0]   d_reg_src1,
   input  [4:0]   d_reg_src2,
   input  [4:0]   e_reg_src1,
   input  [4:0]   e_reg_src2,
   input  [4:0]   e_reg_dest,
   input          e_rslt_src_0,
   input  [4:0]   m_reg_dest,
   input          m_regfl_wr_en,
   input  [4:0]   w_reg_dest,
   input          w_regfl_wr_en,
   //    Output ports definition
   output         f_stall,
   output         d_stall,
   output         d_flush,
   output         e_flush,
   output [1:0]   e_fwd_src_a,
   output [1:0]   e_fwd_src_b
);
   
   //==========================
   // Packages and defines
   //==========================
   import pkg_cpu_typedefs::*;

   //==========================
   // Wire declarations
   //==========================
   logic load_hazard_detected;


   //+--------------------------------------------------------------+//
   //|                     Data Hazards Handling                    |//
   //+--------------------------------------------------------------+//

   //Definition: "Forwarding is necessary when an instruction in the Execute stage has a source register 
   //matching the destination register of an instruction in the Memory or Write Back Stage" 

   //Forwarding -> solving RAW Hazards (Data Hazard)
   //Notes: - memory stage forward has priority because it contain the most recent instruction result
   //       - if the source register is ZERO (0x0) then the forward operation should not be executed 
   //         because this register is wired to 0's (cannot be written)
   assign e_fwd_src_a = ( (e_reg_src1 != 0) & (e_reg_src1 == m_reg_dest) & m_regfl_wr_en ) ? 2'b10 : //Forward from Memory Stage
                        ( (e_reg_src1 != 0) & (e_reg_src1 == w_reg_dest) & w_regfl_wr_en ) ? 2'b01 : //Forward from Write Back Stage
                                                                                             2'b00 ; //No forward needed
   assign e_fwd_src_b = ( (e_reg_src2 != 0) & (e_reg_src2 == m_reg_dest) & m_regfl_wr_en ) ? 2'b10 : //Forward from Memory Stage
                        ( (e_reg_src2 != 0) & (e_reg_src2 == w_reg_dest) & w_regfl_wr_en ) ? 2'b01 : //Forward from Write Back Stage
                                                                                             2'b00 ; //No forward needed
   // Load Hazard
   //Note: LW (load word) instruction has a 2 clock cycles latency (Execute - processing the address of the  
   //memory location and Memory - it takes some time to fetch the data from memory and then sample it on the  
   //next posedge of clock), therefore a hazard may appear if the following 2 instructions had any of their
   //decode source registers equal to the destination register of the load instruction

   //How to fix these hazard for the:
   //first instruction after LW  -> stall the pipeline one clock and forward the data from the Write Back Stage
   //second instruction after LW -> stall the pipeline one clock the data will be sampled on negedge in the reg 
   //                               file and will be ready half a cycle later on the posedge
   //Note: this configuration could trigger a false stall when LW destination is ZERO (but this shows bad software design), 
   // according the the specification ZERO should not be destination for any of the instruction (so this will not be fixed
   // in hardware because adds aditinal logic that slows the CPU and increase the area)
   assign load_hazard_detected = e_rslt_src_0 & ( (e_reg_dest == d_reg_src1) | (e_reg_dest == d_reg_src2) );

   assign f_stall = load_hazard_detected; //Stall the Fetch Stage in case of a load hazard
   assign d_stall = load_hazard_detected; //Stall the Decode Stage in case of a load hazard

   //+--------------------------------------------------------------+//
   //|                   Control Hazards Handling                   |//
   //+--------------------------------------------------------------+//

   // Branch Hazards
   //Note: Currently the CPU predict that the banch will not be taken (because for example loops do not take the branch for many iterations)
   //TODO: If there is time this could be upgraded to a branch predictor buffer with 3 bits that saves the last 3 branch operation if they or 
   //TODO: taken or not and predict if the branch should be taken from decode stage instead (like it was done in the Pentium 4 CPU) -> for that 
   //TODO: I need to move the PCTarget adder in the Decode phase
   //Note: Solved branch hazard by invalidating Execute and Decode Stages if the branch is taken aka PC_SRC is 1 meaning 
   //the PC is written with the value computed by the ALU, so because it takes 2 clocks to see if the branch is taken the 
   //last two fetched in structions are calculated from the PC address associated with the branch instruction
   assign e_flush = load_hazard_detected | pc_src; //Flush the Execute Stage in case of load or branch hazard
   assign d_flush = pc_src;                        //Flush The Decode Stage in case of a branch hazard


   `ifdef DESIGNER_ASSERTIONS
      //TODO add assertions
   `endif

endmodule : cpu_hazard_unit