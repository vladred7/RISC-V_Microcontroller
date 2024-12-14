module cpu_alu #(
    parameter DATA_WIDTH = 32
)(
   //    Input ports definition
   input  [DATA_WIDTH-1:0] in_a,
   input  [DATA_WIDTH-1:0] in_b,
   input             [2:0] op_sel,
   //    Output ports definition
   output                  zero,
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
   assign zero = (alu_out == 0);

   //Designer Assertions
   a_xcheck_alu_out:  assert(!$isunknown(alu_out))       else $error($sformatf("ERROR SVA: alu_out has X!!!"));
   a_xcheck_zero:     assert(!$isunknown(zero))          else $error($sformatf("ERROR SVA: zero has X!!!"));
   a_zero_flag_check: assert(zero === (alu_out === 0))   else $error($sformatf("ERROR SVA: zero is set while alu_out != 0!!!"));
   //TODO add more assertions

endmodule : cpu_alu