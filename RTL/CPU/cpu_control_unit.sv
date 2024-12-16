module cpu_control_unit (
   //    Input ports definition
   input        clk,
   input        rst_n,
   input [6:0]  opc,
   input [2:0]  funct3,
   input        funct7, //FIXME Do I need more bits of this field?
   input        z_flag,
   //    Output ports definition
   output       pc_wr_en,
   output       mem_addr_src,
   output       mem_wr_en,
   output       instr_wr_en,
   output [1:0] result_src,
   output [2:0] alu_op_sel,
   output [1:0] alu_a_src,
   output [1:0] alu_b_src,
   output [1:0] imd_src,
   output       regfl_wr_en
);
   
   import pkg_cpu_typedefs::*;

endmodule : cpu_control_unit