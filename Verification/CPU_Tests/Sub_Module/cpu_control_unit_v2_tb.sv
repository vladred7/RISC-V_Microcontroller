//######################################## Header ########################################
//# Author: Vlad Rosu                                                                    #
//# Description: Testbench for control unit of the pipeline CPU aka v2                   #
//########################################################################################

module cpu_control_unit_v2_tb ();

   import pkg_verification_utils::*;

   cpu_control_unit_v2 dut(
      //    Input ports
      .opc           ( tb_in_opc       ),
      .funct3        ( tb_in_funct3    ),
      .funct7        ( tb_in_funct7    ),
      //    Output ports 
      .jmp           ( dut_jmp         ),
      .bra           ( dut_bra         ),
      .alu_a_src     ( dut_alu_a_src   ),
      .alu_b_src     ( dut_alu_b_src   ),
      .mem_wr_en     ( dut_mem_wr_en   ),
      .regfl_wr_en   ( dut_regfl_wr_en ),
      .imd_src       ( dut_imd_src     ),
      .alu_op_sel    ( dut_alu_op_sel  ),
      .result_src    ( dut_result_src  )
   );

   //DUT Inputs
   cpu_opcode_t   tb_in_opc;
   logic [2:0]    tb_in_funct3;
   logic          tb_in_funct7;

   //DUT Outputs
   logic          dut_jmp;
   logic          dut_bra;
   logic [1:0]    dut_alu_a_src;
   logic          dut_alu_b_src;
   logic          dut_mem_wr_en;
   logic          dut_regfl_wr_en;
   logic [2:0]    dut_imd_src;
   logic [3:0]    dut_alu_op_sel;
   logic [1:0]    dut_result_src;

   //Model signals
   bit            expected_jmp;
   bit            expected_bra;
   bit   [1:0]    expected_alu_a_src;
   bit            expected_alu_b_src;
   bit            expected_mem_wr_en;
   bit            expected_regfl_wr_en;
   bit   [2:0]    expected_imd_src;
   bit   [3:0]    expected_alu_op_sel;
   bit   [1:0]    expected_result_src;

   //TB utilities
   int unsigned   errors;
   int unsigned   test_num;

   function void randomize_test_inputs();
      tb_in_opc      = $urandom();
      tb_in_funct3   = $urandom();
      tb_in_funct7   = $urandom();
   endfunction : randomize_test_inputs

   function logic [15:0] ctrlu_model(logic [31:0] op, logic [31:0] fun3, logic [31:0] fun7);
      bit        model_jmp;
      bit        model_bra;
      bit [ 1:0] model_alu_a_src;
      bit        model_alu_b_src;
      bit        model_mem_wr_en;
      bit        model_regfl_wr_en;
      bit [ 2:0] model_imd_src;
      bit [ 1:0] model_alu_op;
      bit [ 3:0] model_alu_op_sel;
      bit [ 1:0] model_result_src;
      bit [13:0] control_vector;
      bit [15:0] exp_vector;

      case (op)
            LOAD: control_vector = 14'b0_0_00_1_0_1_000_00_01;
          AUI_PC: control_vector = 14'b0_0_11_1_0_1_100_00_00;
             LUI: control_vector = 14'b0_0_10_1_0_1_100_00_00;
            JALR: control_vector = 14'b1_0_00_1_0_1_000_00_10;
          S_TYPE: control_vector = 14'b0_0_00_1_1_0_001_00_00;
          R_TYPE: control_vector = 14'b0_0_00_0_0_1_000_10_00;
          I_TYPE: control_vector = 14'b0_0_00_1_0_1_000_10_00;
          J_TYPE: control_vector = 14'b1_0_11_1_0_1_011_00_10;
          B_TYPE: control_vector = 14'b0_1_00_0_0_0_010_01_00;
         default: control_vector = 14'b0;
      endcase

      {model_jmp, 
       model_bra, 
       model_alu_a_src, 
       model_alu_b_src, 
       model_mem_wr_en, 
       model_regfl_wr_en, 
       model_imd_src, 
       model_alu_op, 
       model_result_src } = control_vector;

      case (model_alu_op)
         2'b00:   model_alu_op_sel = ADD;
         2'b01:   model_alu_op_sel = SUB;
         2'b10:   begin
                     case (fun3)
                        3'b000:  model_alu_op_sel = (op[5] & fun7) ? SUB : ADD;
                        3'b001:  model_alu_op_sel = SLL;
                        3'b010:  model_alu_op_sel = SLT;
                        3'b011:  model_alu_op_sel = SLTU;
                        3'b100:  model_alu_op_sel = XOR;
                        3'b101:  model_alu_op_sel = (fun7) ? SRA : SRL;
                        3'b110:  model_alu_op_sel = OR;
                        3'b111:  model_alu_op_sel = AND;
                     endcase
                  end
         default: model_alu_op_sel = 0;
      endcase

      exp_vector = { model_jmp, 
                     model_bra, 
                     model_alu_a_src, 
                     model_alu_b_src, 
                     model_mem_wr_en, 
                     model_regfl_wr_en, 
                     model_imd_src, 
                     model_alu_op_sel, 
                     model_result_src  };
               
      return exp_vector;
   endfunction : ctrlu_model
   
   initial begin
      
      // X Propagation
      #10;

      test_num = 5000;

      for (int i = 0; i < test_num; i++) begin
         randomize_test_inputs();
         {expected_jmp,
          expected_bra,
          expected_alu_a_src,
          expected_alu_b_src,
          expected_mem_wr_en,
          expected_regfl_wr_en,
          expected_imd_src,
          expected_alu_op_sel,
          expected_result_src} = ctrlu_model(tb_in_opc, tb_in_funct3, tb_in_funct7);
         #1;
         if(expected_jmp         !== dut_jmp         ||
            expected_bra         !== dut_bra         ||
            expected_alu_a_src   !== dut_alu_a_src   ||
            expected_alu_b_src   !== dut_alu_b_src   ||
            expected_mem_wr_en   !== dut_mem_wr_en   ||
            expected_regfl_wr_en !== dut_regfl_wr_en ||
            expected_imd_src     !== dut_imd_src     ||
            expected_alu_op_sel  !== dut_alu_op_sel  ||
            expected_result_src  !== dut_result_src  )
         begin
            errors++;
         end
         #9;
      end

      #1;

      $display("Pass Rate: %3.3f%%",((test_num-errors)/test_num)*100);
      $display("Stopping simulation.");
      $finish;
   end

endmodule : cpu_control_unit_v2_tb