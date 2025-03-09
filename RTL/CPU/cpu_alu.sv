//######################################## Header ########################################
//# Author: Vlad Rosu                                                                    #
//# Description: A parameterizable ALU module                                            #
//########################################################################################

module cpu_alu #(
   parameter DATA_WIDTH = 32
)(
   //    Input ports definition
   input  [DATA_WIDTH-1:0] in_a,
   input  [DATA_WIDTH-1:0] in_b,
   input             [3:0] op_sel,
   //    Output ports definition
   output                  z_flag,
   output [DATA_WIDTH-1:0] alu_out
);

   import pkg_cpu_typedefs::*;

   logic[DATA_WIDTH-1:0] result;
   logic[DATA_WIDTH:0] sub;

   assign sub = in_a - in_b;
   
   //Compute ALU Result
   always_comb begin
      result = '0; //Default case
      case (op_sel)
         ADD : result = in_a + in_b;
         SUB : result = sub[DATA_WIDTH-1:0];
         AND : result = in_a & in_b;
         OR  : result = in_a | in_b;
         XOR : result = in_a ^ in_b;
         SLT : result = (in_a[DATA_WIDTH-1] != in_b[DATA_WIDTH-1]) ? in_a[DATA_WIDTH-1] : sub[DATA_WIDTH];
         SLL : result = in_a << in_b[4:0];
         SRA : result = in_a >>> in_b[4:0];
         SRL : result = in_a >> in_b[4:0];
         SLTU: result = sub[DATA_WIDTH];
      endcase
   end

   //Assign alu_out the result
   assign alu_out = result;

   //Compute ALU Flags
   assign z_flag = (alu_out == 0);

   `ifdef DESIGNER_ASSERTIONS
      a_xcheck_alu_out:  assert(!$isunknown(alu_out))         else $error($sformatf("ERROR SVA: alu_out has X!!!"));
      a_xcheck_zero:     assert(!$isunknown(z_flag))          else $error($sformatf("ERROR SVA: z_flag has X!!!"));
      a_zero_flag_check: assert(z_flag === (alu_out === 0))   else $error($sformatf("ERROR SVA: z_flag is set while alu_out != 0!!!"));
      //TODO add more assertions
   `endif

endmodule : cpu_alu