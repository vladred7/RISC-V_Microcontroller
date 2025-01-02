//######################################## Header ########################################
//# Author: Vlad Rosu                                                                    #
//# Description: Control unit used for pipeline CPU                                    #
//########################################################################################

module cpu_control_unit_v2(
   //    Input ports definition
   input  [6:0] opc,
   input  [2:0] funct3,
   input        funct7, //for RV32I set onlt funct[5] bit is needed for decode
   //    Output ports definition
   output       regfl_wr_en,
   output [1:0] result_src,
   output       mem_wr_en,
   output       jmp,
   output       bra,
   output [2:0] alu_op_sel,
   output [1:0] alu_b_src,
   output [1:0] imd_src
);
   
   import pkg_cpu_typedefs::*;

   //TODO Implement logic for the pipeline controller



endmodule : cpu_control_unit_v2