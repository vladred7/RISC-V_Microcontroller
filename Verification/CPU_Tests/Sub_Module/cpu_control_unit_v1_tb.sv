//######################################## Header ########################################
//# Author: Vlad Rosu                                                                    #
//# Description: Testbench for control unit of the multicycle CPU aka v1                 #
//########################################################################################

module cpu_control_unit_v1_tb ();

   import pkg_verification_utils::*;

   cpu_control_unit_v1 dut(
      //    Input ports
      .clk           ( tb_clk           ),
      .rst_n         ( tb_rst_n         ),
      .opc           ( tb_opcode        ),
      .funct3        ( tb_funct3        ),
      .funct7        ( tb_funct7_5      ),
      .z_flag        ( tb_z_flag        ),
      //    Output ports 
      .pc_wr_en      ( dut_pc_wr_en     ),
      .mem_addr_src  ( dut_mem_addr_src ),
      .mem_wr_en     ( dut_mem_wr_en    ),
      .instr_wr_en   ( dut_instr_wr_en  ),
      .regfl_wr_en   ( dut_regfl_wr_en  ),
      .imd_src       ( dut_imd_src      ),
      .alu_a_src     ( dut_alu_a_src    ),
      .alu_b_src     ( dut_alu_b_src    ),
      .alu_op_sel    ( dut_alu_op_sel   ),
      .result_src    ( dut_result_src   ) 
   );

   //DUT Inputs
   bit            tb_clk;
   bit            tb_rst_n;
   cpu_state_t    tb_internal_fsm_state;
   cpu_opcode_t   tb_opcode;
   logic [ 2:0]   tb_funct3;
   logic          tb_funct7_5;
   logic          tb_z_flag;
   
   //DUT Outputs
   logic          dut_pc_wr_en;
   logic          dut_mem_addr_src;
   logic          dut_mem_wr_en;
   logic          dut_instr_wr_en;
   logic          dut_regfl_wr_en;
   logic [ 1:0]   dut_imd_src;
   logic [ 1:0]   dut_alu_a_src;
   logic [ 1:0]   dut_alu_b_src;
   logic [ 2:0]   dut_alu_op_sel;
   logic [ 1:0]   dut_result_src;

   //Tb variables
   bit            check_clk;
   logic [15:0]   tb_expected_result;
   logic [15:0]   dut_output_vector;
   int unsigned   errors;
   int unsigned   test_num;
   int unsigned   test_count;

   //Classes/functions/tasks
   class tb_stimuli_c;
      local rand cpu_opcode_t   opcode;
      local rand logic [2:0]    funct3;
      local rand logic          funct7_5;
      local rand logic          z_flag;

      //Add constraints to the signals
      constraint ctrl_unit_opcode {opcode inside {LOAD,I_TYPE,AUI_PC,S_TYPE,R_TYPE,LUI,B_TYPE,JALR,J_TYPE};}

      function cpu_opcode_t get_opcode();
         return this.opcode;
      endfunction : get_opcode

      function logic [2:0] get_funct3();
         return this.funct3;
      endfunction : get_funct3

      function logic get_funct7();
         return this.funct7_5;
      endfunction : get_funct7

      function logic get_z_flag();
         return this.z_flag;
      endfunction : get_z_flag
      
   endclass : tb_stimuli_c

   function void randomize_test_inputs();
      tb_stimuli_c stimuli = new();
      
      if(!stimuli.randomize())
         $fatal("Randomization of stimuli failed!");

      tb_opcode   = stimuli.get_opcode();
      tb_funct3   = stimuli.get_funct3();
      tb_funct7_5 = stimuli.get_funct7();
      tb_z_flag   = stimuli.get_z_flag();
   endfunction : randomize_test_inputs

   function logic [15:0] ctrl_unit_model(cpu_opcode_t opcode, logic [2:0] funct3, logic funct7_5, logic z_flag);
      logic          pc_wr_en;
      logic          mem_addr_src;
      logic          mem_wr_en;
      logic          instr_wr_en;
      logic          regfl_wr_en;
      logic [ 1:0]   imd_src;
      logic [ 1:0]   alu_a_src;
      logic [ 1:0]   alu_b_src;
      alu_opcode_t   alu_op_sel;
      logic [ 1:0]   result_src;
      logic          branch;
      logic [ 1:0]   alu_op;

      {pc_wr_en, mem_addr_src, mem_wr_en, instr_wr_en, regfl_wr_en, imd_src, alu_a_src, alu_b_src, alu_op, result_src} = '0;
      
      //Decode imd_src because is independent of the state
      if(opcode inside {LOAD, I_TYPE, JALR}) begin
         imd_src = 2'b00;
      end else if(opcode === S_TYPE) begin
         imd_src = 2'b01;
      end else if(opcode === B_TYPE) begin
         imd_src = 2'b10;
      end else if(opcode === J_TYPE) begin
         imd_src = 2'b11;
      end else if(opcode inside {AUI_PC, LUI}) begin
         //TODO need to define
      end 

      //Decode branch condition
      branch = z_flag; //TODO might need to update this after adding the new branch ops   
            
      //Decode next stage
      if(tb_internal_fsm_state == FETCH) begin
         tb_internal_fsm_state = DECODE;
      end else if(tb_internal_fsm_state == DECODE) begin
         tb_internal_fsm_state = EXECUTE;
      end else if(tb_internal_fsm_state == EXECUTE) begin
         tb_internal_fsm_state = (opcode inside {LOAD, S_TYPE}          ) ? MEM_ACC :
                                 (opcode inside {R_TYPE, I_TYPE, J_TYPE}) ? RFL_WRB :
                                                                            FETCH   ; //TODO: define behaviour for AUIPC and LUI
      end else if(tb_internal_fsm_state == MEM_ACC) begin
         tb_internal_fsm_state = (opcode inside {LOAD}) ? RFL_WRB :
                                                          FETCH   ;
      end else if(tb_internal_fsm_state == RFL_WRB) begin
         tb_internal_fsm_state = FETCH;
      end

      //Decode output signals
      if(tb_internal_fsm_state == FETCH) begin
         pc_wr_en    = 1'b1;
         instr_wr_en = 1'b1;
         alu_b_src   = 2'b10;
         result_src  = 2'b10;
      end else if(tb_internal_fsm_state == DECODE) begin
         alu_a_src = 2'b01;
         alu_b_src = 2'b01;
      end else if(tb_internal_fsm_state == EXECUTE) begin
         alu_a_src  = (opcode inside {LOAD, S_TYPE, R_TYPE, I_TYPE, B_TYPE}) ? 2'b10 :
                      (opcode inside {J_TYPE})                               ? 2'b01 : 
                                                                               2'b00 ; //TODO: define behaviour for AUIPC and LUI
         alu_b_src  = (opcode inside {LOAD, S_TYPE, I_TYPE}) ? 2'b01 :
                      (opcode inside {J_TYPE})               ? 2'b10 : 
                                                               2'b00 ;
         alu_op     = (opcode inside {R_TYPE,I_TYPE}) ? 2'b10 :
                      (opcode inside {B_TYPE})        ? 2'b01 : 
                                                        2'b00 ;
         pc_wr_en   = (opcode inside {J_TYPE}) ?   1'b1 : 
                      (opcode inside {B_TYPE}) ? branch :
                                                   1'b0 ;
      end else if(tb_internal_fsm_state == MEM_ACC) begin
         mem_addr_src = 1'b1;
         mem_wr_en    = (opcode === S_TYPE);
      end else if(tb_internal_fsm_state == RFL_WRB) begin
         result_src  = (opcode inside {LOAD}) ? 2'b01 : 2'b00;
         regfl_wr_en = 1'b1;
      end

      //Decode ALU operation
      alu_op_sel = ADD;
      case({alu_op,funct3,opcode[5],funct7_5}) inside
         7'b00_???_?_?: alu_op_sel = ADD;
         7'b01_???_?_?: alu_op_sel = SUB;
         7'b10_000_1_1: alu_op_sel = SUB;
         7'b10_010_?_?: alu_op_sel = SLT;
         7'b10_110_?_?: alu_op_sel = OR;
         7'b10_111_?_?: alu_op_sel = AND;
      endcase

      return {pc_wr_en, mem_addr_src, mem_wr_en, instr_wr_en, regfl_wr_en, imd_src, alu_a_src, alu_b_src, alu_op_sel, result_src};
   endfunction : ctrl_unit_model


   ////////////////////////////////////
   //          Test sequence         //
   ////////////////////////////////////

   //Bundle the DUT outputs into a single vector for readability 
   assign dut_output_vector = {dut_pc_wr_en, dut_mem_addr_src, dut_mem_wr_en, dut_instr_wr_en, dut_regfl_wr_en, dut_imd_src, dut_alu_a_src, dut_alu_b_src, dut_alu_op_sel, dut_result_src};

   //Clock Generator Thread
   initial begin
      tb_clk <= 0;
      forever #5 tb_clk = !tb_clk;
   end

   //Checking Clock Generator Thread
   initial begin
      check_clk <= 0;
      #1; //Skew this clock from the tb_clock to avoid race conditions of posedge of dut clk
      forever #5 check_clk = !check_clk;
   end

   //Reset Generator Thread
   initial begin
      tb_rst_n = 1;
      #50;
      tb_rst_n = 0;
      repeat(2) @(posedge tb_clk);
      @(negedge tb_clk);
      tb_rst_n = 1;
   end

   //Initialize tb model fsm state with the FETCH stage
   initial tb_internal_fsm_state = FETCH;

   //Main Test Thread
   initial begin
      test_num = 1000;
      test_count = 0;
      #50;
      repeat(2) @(posedge tb_clk);
      //Synchronize with the negedge of clock after reset
      @(negedge tb_clk);
      
      for (int i = 0; i < test_num; i++) begin
         //Wait skewed clock negedge for randomization
         @(negedge check_clk);
         //Randomize the inputs
         randomize_test_inputs();
         //Wait for the posedge of DUT
         @(posedge tb_clk);
         //Wait skewed clock posedge for model update
         @(posedge check_clk);
         //Trigger the verification golden model
         tb_expected_result = ctrl_unit_model(tb_opcode, tb_funct3, tb_funct7_5, tb_z_flag);
         //Wait for the negedge of DUT for checking
         @(negedge tb_clk);
         test_count++;
         if(dut_output_vector !== tb_expected_result)
            errors++;
         
         while(tb_internal_fsm_state != FETCH) begin //Wait for all the stages to finish
            //Wait for the posedge of DUT
            @(posedge tb_clk);
            //Wait skewed clock posedge for model update
            @(posedge check_clk);
            //Trigger the verification golden model
            tb_expected_result = ctrl_unit_model(tb_opcode, tb_funct3, tb_funct7_5, tb_z_flag);
            //Wait for the negedge of DUT for checking
            @(negedge tb_clk);
            test_count++;
            if(dut_output_vector !== tb_expected_result)
               errors++;
         end

      end
      
      $display("Pass Rate: %3.2f%%",((test_count-errors)/real'(test_count))*100);
      $display("Stopping simulation.");
      $finish;   
   end

endmodule : cpu_control_unit_v1_tb