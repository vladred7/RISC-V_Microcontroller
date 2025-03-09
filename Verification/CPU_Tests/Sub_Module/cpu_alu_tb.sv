//######################################## Header ########################################
//# Author: Vlad Rosu                                                                    #
//# Description: Testbench for ALU specialized on 32 bit data                            #
//########################################################################################

module cpu_alu_tb ();

   import pkg_verification_utils::*;

   cpu_alu #(
      .DATA_WIDTH(32)
   ) dut(
      //    Input ports
      .in_a    ( tb_in_a    ),
      .in_b    ( tb_in_b    ),
      .op_sel  ( tb_op_sel  ),
      //    Output ports
      .z_flag  ( alu_z_flag ),
      .alu_out ( alu_out    )
   );

   logic [31:0]   tb_in_a;
   logic [31:0]   tb_in_b;
   alu_opcode_t   tb_op_sel;
   logic          alu_z_flag;
   logic [31:0]   alu_out;

   logic [31:0]   alu_out_expected;
   logic          alu_z_flag_expected;
   int unsigned   errors;
   int unsigned   test_num;

   function void randomize_test_inputs();
      tb_in_a     = $urandom();
      tb_in_b     = $urandom();
      tb_op_sel   = $urandom();
   endfunction : randomize_test_inputs

   function logic [32:0] alu_model(logic [31:0] a, logic [31:0] b, logic [31:0] op);
      logic [31:0] result;
      logic [31:0] diff;
      logic        z;

      result = 0;
      diff = a - b;
      case (op)
         ADD : result = a + b;
         SUB : result = a - b;
         AND : result = a & b;
         OR  : result = a | b;
         XOR : result = a ^ b;
         SLT : result = (a[31] != b[31]) ? a[31] : diff[31];
         SLL : result = a <<  b[4:0];
         SRA : result = a >>> b[4:0];
         SRL : result = a >>  b[4:0];
         SLTU: result = a < b;
      endcase

      z = (result === 0) ? 1'b1 : 1'b0;

      return {z,result};
   endfunction : alu_model
   
   initial begin
      
      // X Propagation
      #10;

      test_num = 1000;

      for (int i = 0; i < test_num; i++) begin
         randomize_test_inputs();
         {alu_z_flag_expected, alu_out_expected} = alu_model(tb_in_a, tb_in_b, tb_op_sel);
         #1;
         if({alu_z_flag, alu_out} !== {alu_z_flag_expected, alu_out_expected})
            errors++;
         #9;
      end

      #1;

      $display("Pass Rate: %3.3f%%",((test_num-errors)/test_num)*100);
      $display("Stopping simulation.");
      $finish;
   end

endmodule : cpu_alu_tb