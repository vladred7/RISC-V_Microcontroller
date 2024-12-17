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
   output       regfl_wr_en,
   output [1:0] imd_src, //Done
   output [1:0] alu_a_src,
   output [1:0] alu_b_src,
   output [2:0] alu_op_sel, //TODO
   output [1:0] result_src
);
   
   import pkg_cpu_typedefs::*;

   cpu_state_t next_state;
   cpu_state_t state;
   cpu_state_t state_ff;

   logic [ 1:0] alu_op;
   logic [12:0] ctrl_vect;

   //==========================
   // CPU FSM
   //==========================
   always_comb begin // Next State Decoder
      next_state = FETCH;
      case (state)
         FETCH:   next_state = DECODE;
         DECODE:  next_state = EXECUTE;
         EXECUTE: begin
                     next_state = FETCH; //decode all posibilities
                     case (opc)
                        7'b0000011,                         //LW
                        7'b0100011: next_state = MEM_ACC;   //SW
                        7'b0110011,                         //R-type
                        7'b0010011,                         //I-type
                        7'b1101111: next_state = RFL_WRB;   //JAL
                        7'b1100011: next_state = FETCH;     //Branch
                     endcase
                  end
         MEM_ACC: next_state = (opc == 7'b0000011) ? RFL_WRB : FETCH; //Only if OPC=LW go to WB stage
         RFL_WRB: next_state = FETCH;
      endcase
   end

   always_ff @(posedge clk or negedge rst_n) begin : state_ff
      if(!rst_n) begin
         state_ff <= FETCH;
      end else begin
         state_ff <= next_state;
      end
   end

   assign state = state_ff;

   //+--------------------------------------------------------------+//
   //| Control signals vector table description                     |//
   //+------------------+-------------------------------------------+//
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
   //| FETCH   |      X | 0 | 0 | 0 | 0 | 0 |  00 |  00 |  00 |  00 |//
   //| DECODE  |      X | 0 | 0 | 0 | 0 | 0 |  00 |  00 |  00 |  00 |//
   //| EXECUTE |  LW/SW | 0 | 0 | 0 | 0 | 0 |  00 |  00 |  00 |  00 |//
   //|         | R-Type | 0 | 0 | 0 | 0 | 0 |  00 |  00 |  00 |  00 |//
   //|         | I-Type | 0 | 0 | 0 | 0 | 0 |  00 |  00 |  00 |  00 |//
   //|         |    JAL | 0 | 0 | 0 | 0 | 0 |  00 |  00 |  00 |  00 |//
   //|         | Branch | 0 | 0 | 0 | 0 | 0 |  00 |  00 |  00 |  00 |//
   //| MEM_ACC |     LW | 0 | 0 | 0 | 0 | 0 |  00 |  00 |  00 |  00 |//
   //|         |     SW | 0 | 0 | 0 | 0 | 0 |  00 |  00 |  00 |  00 |//
   //| RFL_WRB |  LW/SW | 0 | 0 | 0 | 0 | 0 |  00 |  00 |  00 |  00 |//
   //|         | Others | 0 | 0 | 0 | 0 | 0 |  00 |  00 |  00 |  00 |//
   //+---------+--------+---+---+---+---+---+-----+-----+-----+-----+//

   always_comb begin //Output Decoder
      {pc_wr_en, mem_addr_src, mem_wr_en, instr_wr_en, result_src, alu_op, alu_a_src, alu_b_src, regfl_wr_en} = '0;
      case (state)
         FETCH:    
         DECODE:  
         EXECUTE: 
         MEM_ACC: 
         RFL_WRB: 
      endcase
   end

   //Assign the control vector values to their specific wires
   assign {pc_wr_en, mem_addr_src, mem_wr_en, instr_wr_en, regfl_wr_en, alu_a_src, alu_b_src, alu_op, result_src} = ctrl_vect;



   //==========================
   // ALU DEC
   //==========================
   // Short description table
   //-----------------------
   // op[5] | 0 | ALU operation selected by 
   //       | 1
   // 
   always_comb begin
      alu_op_sel = '0;
      case ()
      

      endcase
   end

   //==========================
   // SIGN-EXT DEC
   //==========================

   always_comb begin
      imd_src = '0;
      case (opc)
         7'b0000011, 
         7'b0010011,
         7'b1100111: imd_src = 2'b00; //I-Type opcode
         7'b0100011: imd_src = 2'b01; //S-Type opcode
         7'b1100011: imd_src = 2'b10; //B-Type opcode
         7'b1101111: imd_src = 2'b11; //J-Type opcode
      endcase
   end

   `ifdef DESIGNER_ASSERTIONS
      //TODO add assertions
   `endif

endmodule : cpu_control_unit