module cpu_alu #(
   parameter DATA_WIDTH = 32
)(
   //    Input ports definition
   input  [DATA_WIDTH-1:0] in_a,
   input  [DATA_WIDTH-1:0] in_b,
   input             [2:0] op_sel,
   //    Output ports definition
   output                  z_flag,
   output [DATA_WIDTH-1:0] alu_out
);

   import pkg_cpu_typedefs::*;
   
   //Compute ALU Result
   always_comb begin
      alu_out = '0; //Default case
      case (op_sel)
         ADD: alu_out = in_a + in_b;
         SUB: alu_out = in_a - in_b;
         AND: alu_out = in_a & in_b;
         OR : alu_out = in_a | in_b;
         SLT: alu_out = in_a < in_b;
         //TODO implement rest of the ops
      endcase
   end

   //Compute ALU Flags
   assign z_flag = (alu_out == 0);

   `ifdef DESIGNER_ASSERTIONS
      a_xcheck_alu_out:  assert(!$isunknown(alu_out))         else $error($sformatf("ERROR SVA: alu_out has X!!!"));
      a_xcheck_zero:     assert(!$isunknown(z_flag))          else $error($sformatf("ERROR SVA: z_flag has X!!!"));
      a_zero_flag_check: assert(z_flag === (alu_out === 0))   else $error($sformatf("ERROR SVA: z_flag is set while alu_out != 0!!!"));
      //TODO add more assertions
   `endif

endmodule : cpu_alu