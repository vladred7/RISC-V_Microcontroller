//######################################## Header ########################################
//# Author: Vlad Rosu                                                                    #
//# Description: Control unit used for pipeline CPU                                      #
//########################################################################################

module cpu_control_unit_v2(
   //    Input ports definition
   input  [6:0] opc,
   input  [2:0] funct3,
   input        funct7, //for RV32I set onlt funct[5] bit is needed for decode
   //    Output ports definition
   output       jmp,
   output       bra,
   output [1:0] alu_a_src,
   output       alu_b_src,
   output       mem_wr_en,
   output       regfl_wr_en,
   output [2:0] imd_src,
   output [2:0] alu_op_sel,
   output [1:0] result_src
);
   
   //==========================
   // Packages and defines
   //==========================
   import pkg_cpu_typedefs::*;

   //==========================
   // Wire declarations
   //==========================
   logic [ 1:0]   alu_op;
   logic [13:0]   ctrl_vect;
   logic [ 2:0]   alu_dec_result;

   //======================================================//
   // CPU Decoder                                          //
   //======================================================//
   //+----------------------------------------------------+//
   //| Control signals vector table description           |//
   //+----------------------------------------------------+//
   //|        | j | b |  a  | a | m | r |  i  |  a  |  r  |//
   //|        | m | r |  l  | l | e | e |  m  |  l  |  e  |//
   //|        | p | a |  u  | u | m | g |  d  |  u  |  s  |//
   //|        |   |   |  \  | \ | \ | f |  \  |  \  |  u  |//
   //|        |   |   |  a  | b | w | l |  s  |  o  |  l  |//
   //|        |   |   |  \  | \ | r | \ |  r  |  p  |  t  |//
   //|        |   |   |  s  | s | \ | w |  c  |     |  \  |//
   //|        |   |   |  r  | r | e | r |     |     |  s  |//
   //|        |   |   |  c  | c | n | \ |     |     |  r  |//
   //+--------|   |   |     |   |   | e |     |     |  c  |//
   //| Instr  |   |   |     |   |   | n |     |     |     |//
   //+--------+---+---+-----+---+---+---+-----+-----+-----+//
   //|   LOAD | 0 | 0 |  00 | 1 | 0 | 1 | 000 |  00 |  01 |//
   //| AUI_PC | 0 | 0 |  11 | 1 | 0 | 1 | 100 |  00 |  00 |//
   //|    LUI | 0 | 0 |  10 | 1 | 0 | 1 | 100 |  00 |  00 |//
   //|   JALR | 1 | 0 |  00 | 1 | 0 | 1 | 000 |  00 |  10 |//
   //| S_TYPE | 0 | 0 |  00 | 1 | 1 | 0 | 001 |  00 |  xx |//
   //| R_TYPE | 0 | 0 |  00 | 0 | 0 | 1 | xxx |  10 |  00 |//
   //| I_TYPE | 0 | 0 |  00 | 1 | 0 | 1 | 000 |  10 |  00 |//
   //| J_TYPE | 1 | 0 |  11 | 1 | 0 | 1 | 011 |  00 |  10 |//
   //| B_TYPE | 0 | 1 |  00 | 0 | 0 | 0 | 010 |  01 |  xx |//
   //+--------+---+---------------------------------------+//
   //| Legend | x | Don't care                            |//
   //+--------+---+---------------------------------------+//

   always_comb begin
      ctrl_vect = '0;
      case (opc)
           LOAD: ctrl_vect = 14'b0_0_00_1_0_1_000_00_01;
         AUI_PC: ctrl_vect = 14'b0_0_11_1_0_1_100_00_00;
            LUI: ctrl_vect = 14'b0_0_10_1_0_1_100_00_00;
           JALR: ctrl_vect = 14'b1_0_00_1_0_1_000_00_10;
         S_TYPE: ctrl_vect = 14'b0_0_00_1_1_0_001_00_00;
         R_TYPE: ctrl_vect = 14'b0_0_00_0_0_1_000_10_00;
         I_TYPE: ctrl_vect = 14'b0_0_00_1_0_1_000_10_00;
         J_TYPE: ctrl_vect = 14'b1_0_11_1_0_1_011_00_10;
         B_TYPE: ctrl_vect = 14'b0_1_00_0_0_0_010_01_00;
      endcase
   end

   assign {jmp, bra, alu_a_src, alu_b_src, mem_wr_en, regfl_wr_en, imd_src, alu_op, result_src} = ctrl_vect;

   //=====================================================//
   // ALU DEC                                             //
   //=====================================================//
   //-----------------------------------------------------//
   //|                Inputs                |   Output   |//
   //-----------------------------------------------------//
   //| alu_op | funct3 | opc[5] | funct7[5] | alu_op_sel |//
   //|   00   |    x   |    x   |     x     |     000    |//
   //|   01   |    x   |    x   |     x     |     001    |//
   //|   10   |   000  |    0   |     0     |     000    |//
   //|   10   |   000  |    0   |     1     |     000    |//
   //|   10   |   000  |    1   |     0     |     000    |//
   //|   10   |   000  |    1   |     1     |     001    |//
   //|   10   |   010  |    x   |     x     |     101    |//
   //|   10   |   110  |    x   |     x     |     011    |//
   //|   10   |   111  |    x   |     x     |     010    |//
   //-----------------------------------------------------//
   always_comb begin
      alu_dec_result = '0;
      case (alu_op)
         2'b00:   alu_dec_result = ADD;
         2'b01:   alu_dec_result = SUB;
         2'b10:   begin
                     case (funct3)
                        3'b000:  alu_dec_result = (opc[5] & funct7) ? SUB : ADD; 
                        3'b010:  alu_dec_result = SLT;
                        3'b110:  alu_dec_result = OR;
                        3'b111:  alu_dec_result = AND;
                     endcase
                  end
      endcase
   end

   assign alu_op_sel = alu_dec_result;


   `ifdef DESIGNER_ASSERTIONS
      //TODO add assertions
   `endif

endmodule : cpu_control_unit_v2