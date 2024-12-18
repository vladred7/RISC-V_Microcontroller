module cpu_control_unit (
   //    Input ports definition
   input        clk,
   input        rst_n,
   input [6:0]  opc,
   input [2:0]  funct3,
   input        funct7, //for RV32I set onlt funct[5] bit is needed for decode
   input        z_flag,
   //    Output ports definition
   output       pc_wr_en,
   output       mem_addr_src,
   output       mem_wr_en,
   output       instr_wr_en,
   output       regfl_wr_en,
   output [1:0] imd_src,
   output [1:0] alu_a_src,
   output [1:0] alu_b_src,
   output [2:0] alu_op_sel,
   output [1:0] result_src
);
   
   import pkg_cpu_typedefs::*;

   cpu_state_t    next_state;
   cpu_state_t    state;
   cpu_state_t    state_ff;

   logic [ 1:0]   alu_op;
   logic [12:0]   ctrl_vect;
   logic          branch;
   logic [ 2:0]   alu_dec_result;
   logic [ 1:0]   sign_ext_dec_result;

   //==========================
   // CPU FSM
   //==========================
   always_comb begin // Next State Decoder
      next_state = FETCH;
      case (state)
         FETCH:   next_state = DECODE;
         DECODE:  next_state = EXECUTE;
         EXECUTE: begin
                     case (opc)
                        LOAD,
                        S_TYPE:  next_state = MEM_ACC;
                        R_TYPE,
                        I_TYPE,
                        J_TYPE:  next_state = RFL_WRB;
                        B_TYPE:  next_state = FETCH;
                     endcase
                  end
         MEM_ACC: next_state = (opc == LOAD) ? RFL_WRB : FETCH;
         RFL_WRB: next_state = FETCH;
      endcase
   end

   always_ff @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
         state_ff <= FETCH;
      end else begin
         state_ff <= next_state;
      end
   end

   assign state = state_ff;

   //+--------------------------------------------------------------+//
   //| Control signals vector table description                     |//
   //+--------------------------------------------------------------+//
   //|                  | p | m | m | i | r |  a  |  a  |  a  |  r  |//
   //|                  | c | e | e | n | e |  l  |  l  |  l  |  e  |//
   //|                  | \ | m | m | s | g |  u  |  u  |  u  |  s  |//
   //|                  | w | \ | \ | t | f |  \  |  \  |  \  |  u  |//
   //|                  | r | a | w | r | l |  a  |  b  |  o  |  l  |//
   //|                  | \ | d | r | \ | \ |  \  |  \  |  p  |  t  |//
   //|                  | e | d | \ | w | w |  s  |  s  |     |  \  |//
   //|                  | n | r | e | r | r |  r  |  r  |     |  s  |//
   //|                  |   | \ | n | \ | \ |  c  |  c  |     |  r  |//
   //|                  |   | s |   | e | e |     |     |     |  c  |//
   //+------------------|   | r |   | n | n |     |     |     |     |//
   //|  STATE  | Instr  |   | c |   |   |   |     |     |     |     |//
   //+---------+--------+---+---+---+---+---+-----+-----+-----+-----+//
   //| FETCH   |      x | 1 | 0 | 0 | 1 | 0 |  00 |  10 |  00 |  10 |//
   //| DECODE  |      x | 0 | 0 | 0 | 0 | 0 |  01 |  01 |  00 |  00 |//
   //| EXECUTE |  LD/ST | 0 | 0 | 0 | 0 | 0 |  10 |  01 |  00 |  00 |//
   //|         | R-Type | 0 | 0 | 0 | 0 | 0 |  10 |  00 |  10 |  00 |//
   //|         | I-Type | 0 | 0 | 0 | 0 | 0 |  10 |  01 |  10 |  00 |//
   //|         | J_TYPE | 1 | 0 | 0 | 0 | 0 |  01 |  10 |  00 |  00 |//
   //|         | B-Type | Z | 0 | 0 | 0 | 0 |  10 |  00 |  01 |  00 |//
   //| MEM_ACC |   LOAD | 0 | 1 | 0 | 0 | 0 |  00 |  00 |  00 |  00 |//
   //|         | S_TYPE | 0 | 1 | 1 | 0 | 0 |  00 |  00 |  00 |  00 |//
   //| RFL_WRB |  LD/ST | 0 | 0 | 0 | 0 | 1 |  00 |  00 |  00 |  01 |//
   //|         | Others | 0 | 0 | 0 | 0 | 1 |  00 |  00 |  00 |  00 |//
   //+---------+--------+--------------------------------------------//
   //|  Legend |      x | Don't care                                 //
   //|         |      Z | Zero bit flag                              //
   //|         |  LD/ST | LOAD or S_TYPE                              //
   //+---------+--------+--------------------------------------------//
  
   //TODO Decode remaining instructions
   always_comb begin //Output Decoder (This could be optimized but I chose not to for flexibility reasons)
      ctrl_vect = '0;
      case (state)
         FETCH  :                ctrl_vect = 13'b1_0_0_1_0_00_10_00_10;
         DECODE :                ctrl_vect = 13'b0_0_0_0_0_01_01_00_00;
         EXECUTE: begin
                     case(opc)
                        LOAD,
                        S_TYPE : ctrl_vect = 13'b0_0_0_0_0_10_01_00_00;
                        //LUI    : ctrl_vect = ;
                        R_TYPE : ctrl_vect = 13'b0_0_0_0_0_10_00_10_00;
                        I_TYPE : ctrl_vect = 13'b0_0_0_0_0_10_01_10_00;
                        //AUI_PC : ctrl_vect = ;
                        //JALR   : ctrl_vect = ;
                        J_TYPE : ctrl_vect = 13'b1_0_0_0_0_01_10_00_00;
                        B_TYPE : ctrl_vect = {branch, 12'b0_0_0_0_10_00_01_00}; //branch if zero (TODO add support for other branch types)
                     endcase
                  end
         MEM_ACC: begin
                     case(opc)
                        LOAD   : ctrl_vect = 13'b0_1_0_0_0_00_00_00_00;
                        S_TYPE : ctrl_vect = 13'b0_1_1_0_0_00_00_00_00;
                     endcase
                  end
         RFL_WRB: begin
                     case(opc)
                        LOAD,
                        S_TYPE : ctrl_vect = 13'b0_0_0_0_1_00_00_00_01;
                        R_TYPE,
                        I_TYPE,
                        J_TYPE : ctrl_vect = 13'b0_0_0_0_1_00_00_00_00;
                     endcase
                  end
      endcase
   end

   //Assign the control vector values to their specific wires
   assign {pc_wr_en, mem_addr_src, mem_wr_en, instr_wr_en, regfl_wr_en, alu_a_src, alu_b_src, alu_op, result_src} = ctrl_vect;

   //TODO Decode all branch types
   //==========================
   // Branch DEC
   //==========================
   always_comb begin
      branch = '0;
      case (funct3)
         3'b000: branch = z_flag;
         //3'b001: branch = ;
         //3'b010: branch = ;
         //3'b011: branch = ;
         //3'b100: branch = ;
         //3'b101: branch = ;
         //3'b110: branch = ;
         //3'b111: branch = ;
      endcase
   end

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

   //==========================
   // SIGN-EXT DEC
   //==========================
   always_comb begin
      sign_ext_dec_result = '0;
      case (opc)
         LOAD,
         I_TYPE,
         JALR     : sign_ext_dec_result = 2'b00;
         S_TYPE   : sign_ext_dec_result = 2'b01;
         B_TYPE   : sign_ext_dec_result = 2'b10;
         J_TYPE   : sign_ext_dec_result = 2'b11;
      endcase
   end

   assign imd_src = sign_ext_dec_result;


   `ifdef DESIGNER_ASSERTIONS
      //TODO add assertions
   `endif

endmodule : cpu_control_unit