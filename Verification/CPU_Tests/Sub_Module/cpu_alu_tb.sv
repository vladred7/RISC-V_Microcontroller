//######################################## Header ########################################
//# Author: Vlad Rosu                                                                    #
//# Description: Testbench for ALU specialized on 32 bit data                            #
//########################################################################################

module cpu_alu_tb ();

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

   typedef enum bit [2:0] { ADD = 3'b000, SUB = 3'b001, AND = 3'b010, OR = 3'b011, SLT = 3'b101} alu_opcode_t;

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
      logic        z;

      result = 0;
      case (op)
         ADD: result = a + b;
         SUB: result = a - b;
         AND: result = a & b;
         OR : result = a | b;
         SLT: result = a < b;
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