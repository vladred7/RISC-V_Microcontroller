//######################################## Header ########################################
//# Author: Vlad Rosu                                                                    #
//# Description: Top file for the pipeline CPU aka v2, containing all pipeline stage     #
//#              registers and all the connections between the modules                   #
//########################################################################################

module cpu_pipeline_v2 #(
   parameter ADDR_WIDTH          = 32,
   parameter DATA_WIDTH          = 32,
   parameter REG_FILE_ADDR_WIDTH = 5
)(
   //    Input ports definition
   input                   sys_clk,
   input                   sys_rst_n,
   input  [DATA_WIDTH-1:0] pfm_rd_instr,
   input  [DATA_WIDTH-1:0] dfm_rd_data,
   //    Output ports definition
   output [ADDR_WIDTH-1:0] pfm_req_addr,
   output [ADDR_WIDTH-1:0] dfm_req_addr,
   output                  dfm_wr_en,
   output [DATA_WIDTH-1:0] dfm_wr_data
);

   //==========================
   // Packages and defines
   //==========================
   import pkg_cpu_typedefs::*;

   //==========================
   // Wire declarations
   //==========================
   fetch_data_path_t       f_stage;          //pipeline data path for Fetch stage
   decode_data_path_t      d_stage;          //pipeline data path for Decode stage
   execute_data_path_t     e_stage;          //pipeline data path for Execute stage
   memory_data_path_t      m_stage;          //pipeline data path for Memory stage
   wrback_data_path_t      w_stage;          //pipeline data path for Write Back stage
   execute_ctrl_path_t     e_ctrl_stage;     //pipeline control path for Execute stage
   memory_ctrl_path_t      m_ctrl_stage;     //pipeline control path for Memory stage
   wrback_ctrl_path_t      w_ctrl_stage;     //pipeline control path for Write Back stage
   logic                   f_stall;
   logic                   d_stall;
   logic                   d_flush;
   logic                   e_flush;
   logic            [1:0]  e_fwd_src_a;
   logic            [1:0]  e_fwd_src_b;

   instr_t                 f_instr;
   logic [ADDR_WIDTH-1:0]  f_pc_next;
   logic                   d_regfl_wr_en;
   logic            [1:0]  d_result_src;
   logic                   d_mem_wr_en;
   logic                   d_jmp;
   logic                   d_bra;
   logic            [2:0]  d_alu_op_sel;
   logic            [1:0]  d_alu_a_src;
   logic                   d_alu_b_src;
   logic            [2:0]  d_imd_src;
   logic [DATA_WIDTH-1:0]  d_imd_ext_data;
   logic [DATA_WIDTH-1:0]  d_regfl_data_a;
   logic [DATA_WIDTH-1:0]  d_regfl_data_b;
   logic [DATA_WIDTH-1:0]  e_fwd_a_mux_out;
   logic [DATA_WIDTH-1:0]  e_fwd_b_mux_out;
   logic [DATA_WIDTH-1:0]  e_alu_in_a;
   logic [DATA_WIDTH-1:0]  e_alu_in_b;
   logic                   e_alu_z_flag;
   logic [DATA_WIDTH-1:0]  e_alu_out;
   logic [ADDR_WIDTH-1:0]  e_bra_target_addr;
   logic [ADDR_WIDTH-1:0]  e_pc_target_addr;
   logic                   e_pc_in_src;      //pc input mux selection
   logic [DATA_WIDTH-1:0]  m_rd_data;
   logic [DATA_WIDTH-1:0]  w_result;         //result mux output


   //==========================
   // Flip-flop declarations
   //==========================
   fetch_data_path_t       f_stage_ff;       //pipeline data path flip flop for Fetch stage
   decode_data_path_t      d_stage_ff;       //pipeline data path flip flop for Decode stage
   execute_data_path_t     e_stage_ff;       //pipeline data path flip flop for Execute stage
   memory_data_path_t      m_stage_ff;       //pipeline data path flip flop for Memory stage
   wrback_data_path_t      w_stage_ff;       //pipeline data path flip flop for Write Back stage
   execute_ctrl_path_t     e_ctrl_stage_ff;  //pipeline control path flip flop for Execute stage
   memory_ctrl_path_t      m_ctrl_stage_ff;  //pipeline control path flip flop for Memory stage
   wrback_ctrl_path_t      w_ctrl_stage_ff;  //pipeline control path flip flop for Write Back stage

   //+--------------------------------------------------------------+//
   //|                      CPU Control System                      |//
   //+--------------------------------------------------------------+//

   //==========================
   // Control Unit Logic
   //==========================
   cpu_control_unit_v2 ctrl_unit(
      //    Input ports
      .opc           ( d_stage.d_instr.instruction.opc         ),
      .funct3        ( d_stage.d_instr.instruction.funct3      ),
      .funct7        ( d_stage.d_instr.instruction.funct7[5]   ),
      //    Output ports 
      .jmp           ( d_jmp                                   ),
      .bra           ( d_bra                                   ),
      .alu_a_src     ( d_alu_a_src                             ),
      .alu_b_src     ( d_alu_b_src                             ),
      .mem_wr_en     ( d_mem_wr_en                             ),
      .regfl_wr_en   ( d_regfl_wr_en                           ),
      .imd_src       ( d_imd_src                               ),
      .alu_op_sel    ( d_alu_op_sel                            ),
      .result_src    ( d_result_src                            )
   );

   //Execute Stage
   always_ff @(posedge sys_clk or negedge sys_rst_n) begin
      if(!sys_rst_n) begin //async reset active low
         e_ctrl_stage_ff <= '0;
      end else begin
         if(e_flush) begin //sync reset when flushed (active high)
            e_ctrl_stage_ff <= '0;
         end else begin
            e_ctrl_stage_ff.e_regfl_wr_en <= d_regfl_wr_en;
            e_ctrl_stage_ff.e_result_src  <= d_result_src;
            e_ctrl_stage_ff.e_mem_wr_en   <= d_mem_wr_en;
            e_ctrl_stage_ff.e_jmp         <= d_jmp;
            e_ctrl_stage_ff.e_bra         <= d_bra;
            e_ctrl_stage_ff.e_alu_op_sel  <= d_alu_op_sel;
            e_ctrl_stage_ff.e_alu_a_src   <= d_alu_a_src;
            e_ctrl_stage_ff.e_alu_b_src   <= d_alu_b_src;
         end
      end
   end

   assign e_ctrl_stage = e_ctrl_stage_ff;

   //Memory Stage
   always_ff @(posedge sys_clk or negedge sys_rst_n) begin
      if(!sys_rst_n) begin
         m_ctrl_stage_ff <= '0;
      end else begin
         m_ctrl_stage_ff.m_regfl_wr_en <= e_ctrl_stage.e_regfl_wr_en;
         m_ctrl_stage_ff.m_result_src  <= e_ctrl_stage.e_result_src;
         m_ctrl_stage_ff.m_mem_wr_en   <= e_ctrl_stage.e_mem_wr_en;
      end
   end

   assign m_ctrl_stage = m_ctrl_stage_ff;
   //Control signal for Program Counter in case of jump/branch
   assign e_pc_in_src = e_ctrl_stage.e_jmp | (e_ctrl_stage.e_bra & e_alu_z_flag);

   //Write Back Stage
   always_ff @(posedge sys_clk or negedge sys_rst_n) begin
      if(!sys_rst_n) begin
         w_ctrl_stage_ff <= '0;
      end else begin
         w_ctrl_stage_ff.w_regfl_wr_en <= m_ctrl_stage.m_regfl_wr_en;
         w_ctrl_stage_ff.w_result_src  <= m_ctrl_stage.m_result_src;
      end
   end

   assign w_ctrl_stage = w_ctrl_stage_ff;

   //==========================
   // Hazard Unit Logic
   //==========================
   cpu_hazard_unit hazard_unit(
      //    Input ports definition
      .pc_src        ( e_pc_in_src                             ),
      .d_reg_src1    ( d_stage.d_instr.instruction.rs1         ),
      .d_reg_src2    ( d_stage.d_instr.instruction.rs2         ),
      .e_reg_src1    ( e_stage.e_rs1                           ),
      .e_reg_src2    ( e_stage.e_rs2                           ),
      .e_reg_dest    ( e_stage.e_rd                            ),
      .e_rslt_src_0  ( e_ctrl_stage.e_result_src[0]            ),
      .m_reg_dest    ( m_stage.m_rd                            ),
      .m_regfl_wr_en ( m_ctrl_stage.m_regfl_wr_en              ),
      .w_reg_dest    ( w_stage.w_rd                            ),
      .w_regfl_wr_en ( w_ctrl_stage.w_regfl_wr_en              ),
      //    Output ports definition
      .f_stall       ( f_stall                                 ),
      .d_stall       ( d_stall                                 ),
      .d_flush       ( d_flush                                 ),
      .e_flush       ( e_flush                                 ),
      .e_fwd_src_a   ( e_fwd_src_a                             ),
      .e_fwd_src_b   ( e_fwd_src_b                             )
   );


   //+--------------------------------------------------------------+//
   //|                          Fetch Stage                         |//
   //+--------------------------------------------------------------+//

   //==========================
   // Program Counter Logic
   //==========================
   assign f_pc_next = e_pc_in_src ? e_pc_target_addr : (f_stage.f_pc_val + 4);

   //==========================
   // Fetch Stage Flop
   //==========================
   always_ff @(posedge sys_clk or negedge sys_rst_n) begin
      if(!sys_rst_n) begin
         f_stage_ff <= '0;
      end else begin
         if(!f_stall) begin
            f_stage_ff.f_pc_val <= f_pc_next;
         end
      end
   end

   assign f_stage = f_stage_ff;

   //==========================
   // PFM Logic
   //==========================
   assign pfm_req_addr  = f_stage.f_pc_val;
   assign f_instr       = pfm_rd_instr;


   //+--------------------------------------------------------------+//
   //|                         Decode Stage                         |//
   //+--------------------------------------------------------------+//

   //==========================
   // Decode Stage Flop
   //==========================
   always_ff @(posedge sys_clk or negedge sys_rst_n) begin
      if(!sys_rst_n) begin //async reset active low
         d_stage_ff <= '0;
      end else begin
         if(d_flush) begin //sync reset when flushed (active high)
            d_stage_ff <= '0;
         end else if(!d_stall) begin //enable active low
            d_stage_ff.d_instr   <= f_instr; //FIXME need d_instr.instruction? Probably not
            d_stage_ff.d_pc_val  <= f_stage.f_pc_val;
            d_stage_ff.d_pc_incr <= f_pc_next;
         end
      end
   end

   assign d_stage = d_stage_ff;

   //==========================
   // Register File Logic
   //==========================
   cpu_reg_bank #(
      .ADDR_WIDTH(REG_FILE_ADDR_WIDTH),
      .DATA_WIDTH(DATA_WIDTH)
   ) reg_file(
      //    Input ports
      //NOTE: Reg file write is done on the negedge of the clk because the rest of the logic executes on posedge
      //      so when data is sampled on negedge will be available half a cycle later on the next posedge
      //      This solves some potential RAW(read after write) hazards because when the data computed for an 
      //      instruction pass the Write Back Stage, for sure it will be available half a cycle later for read
      //      in the Decode Stage 
      .clk           ( !sys_clk                                ), //INVERTED SYS CLOCK!!!
      .rst_n         ( sys_rst_n                               ),
      .a1            ( d_stage.d_instr.instruction.rs1         ),
      .a2            ( d_stage.d_instr.instruction.rs2         ),
      .a3            ( w_stage.w_rd                            ),
      .wen3          ( w_ctrl_stage.w_regfl_wr_en              ),
      .wd3           ( w_result                                ),
      //    Output ports
      .rd1           ( d_regfl_data_a                          ),
      .rd2           ( d_regfl_data_b                          )
   );

   //==========================
   // Sign Extension Logic
   //==========================
   cpu_sign_extend_unit #(
      .DATA_WIDTH(DATA_WIDTH)
   ) sign_ext_unit(
      //    Input ports
      .imd           ( d_stage.d_instr.data.imd_data           ),
      .imd_src       ( d_imd_src                               ),
      //    Output ports
      .imd_ext       ( d_imd_ext_data                          )
   );

   //+--------------------------------------------------------------+//
   //|                         Execute Stage                        |//
   //+--------------------------------------------------------------+//

   //==========================
   // Execute Stage Flop
   //==========================
   always_ff @(posedge sys_clk or negedge sys_rst_n) begin
      if(!sys_rst_n) begin //async reset active low
         e_stage_ff <= '0;
      end else begin
         if(e_flush) begin //sync reset when flushed (active high)
            e_stage_ff <= '0;
         end else begin
            e_stage_ff.e_regfl_data_a  <= d_regfl_data_a;
            e_stage_ff.e_regfl_data_b  <= d_regfl_data_b;
            e_stage_ff.e_pc_val        <= d_stage.d_pc_val;
            e_stage_ff.e_pc_incr       <= d_stage.d_pc_incr;
            e_stage_ff.e_rs2           <= d_stage.d_instr.instruction.rs2;
            e_stage_ff.e_rs1           <= d_stage.d_instr.instruction.rs1;
            e_stage_ff.e_rd            <= d_stage.d_instr.instruction.rd;
            e_stage_ff.e_imd_data      <= d_imd_ext_data;
         end
      end
   end

   assign e_stage = e_stage_ff;

   //==========================
   // ALU Logic
   //==========================
   //Data forward mux for ALU source A
   always_comb begin
      e_fwd_a_mux_out = '0;
      case (e_fwd_src_a)
         2'b00: e_fwd_a_mux_out = e_stage.e_regfl_data_a;  //no data forward needed
         2'b01: e_fwd_a_mux_out = w_result;                //forword data from Write Back stage
         2'b10: e_fwd_a_mux_out = m_stage.m_alu_result;    //forword data from Memory stage
      endcase
   end

   //Select between mux out of src A, all 0's(LUI) and PC(AUIPC,JAL)
   always_comb begin
      e_alu_in_a = '0;
      case (e_ctrl_stage.e_alu_a_src)
         2'b00: e_alu_in_a = e_fwd_a_mux_out;
         2'b10: e_alu_in_a = '0;
         2'b11: e_alu_in_a = e_stage.e_pc_val;
      endcase
   end

   //Data forward mux for ALU source B
   always_comb begin
      e_fwd_b_mux_out = '0;
      case (e_fwd_src_b)
         2'b00: e_fwd_b_mux_out = e_stage.e_regfl_data_b;  //no data forward needed
         2'b01: e_fwd_b_mux_out = w_result;                //forword data from Write Back stage
         2'b10: e_fwd_b_mux_out = m_stage.m_alu_result;    //forword data from Memory stage
      endcase
   end

   //Select between mux out of src B and immediate data
   assign e_alu_in_b = (e_ctrl_stage.e_alu_b_src) ? e_stage.e_imd_data : e_fwd_b_mux_out;

   cpu_alu #(
      .DATA_WIDTH(DATA_WIDTH)
   ) alu(
      //    Input ports
      .in_a          ( e_alu_in_a                              ),
      .in_b          ( e_alu_in_b                              ),
      .op_sel        ( e_ctrl_stage.e_alu_op_sel               ),
      //    Output ports
      .z_flag        ( e_alu_z_flag                            ),
      .alu_out       ( e_alu_out                               )
   );

   //Calculate the target address for branch operations
   assign e_bra_target_addr = e_stage.e_pc_val + e_stage.e_imd_data;

   //Select the target address from ALU in case of jump otherwise select branch target address
   assign e_pc_target_addr = (e_ctrl_stage.e_jmp) ? e_alu_out : e_bra_target_addr;


   //+--------------------------------------------------------------+//
   //|                         Memory Stage                         |//
   //+--------------------------------------------------------------+//
   
   //==========================
   // Memory Stage Flop
   //==========================
   always_ff @(posedge sys_clk or negedge sys_rst_n) begin
      if(!sys_rst_n) begin //async reset active low
         m_stage_ff <= '0;
      end else begin
         m_stage_ff.m_alu_result <= e_alu_out;
         m_stage_ff.m_wr_data    <= e_fwd_b_mux_out;
         m_stage_ff.m_pc_incr    <= e_stage.e_pc_incr;
         m_stage_ff.m_rd         <= e_stage.e_rd;
      end
   end

   assign m_stage = m_stage_ff;

   //==========================
   // DFM Logic
   //==========================
   assign dfm_req_addr  = m_stage.m_alu_result;
   assign dfm_wr_data   = m_stage.m_wr_data;
   assign dfm_wr_en     = m_ctrl_stage.m_mem_wr_en;
   assign m_rd_data     = dfm_rd_data;


   //+--------------------------------------------------------------+//
   //|                       Write Back Stage                       |//
   //+--------------------------------------------------------------+//

   //==========================
   // Write Back Stage Flop
   //==========================
   always_ff @(posedge sys_clk or negedge sys_rst_n) begin
      if(!sys_rst_n) begin //async reset active low
         w_stage_ff <= '0;
      end else begin
         w_stage_ff.w_alu_result <= m_stage.m_alu_result;
         w_stage_ff.w_rd_data    <= m_rd_data;
         w_stage_ff.w_pc_incr    <= m_stage.m_pc_incr;
         w_stage_ff.w_rd         <= m_stage.m_rd;
      end
   end

   assign w_stage = w_stage_ff;

   //Result Mux
   always_comb begin
      w_result = '0;
      case (w_ctrl_stage.w_result_src)
         2'b00: w_result = w_stage.w_alu_result;
         2'b01: w_result = w_stage.w_rd_data;
         2'b10: w_result = w_stage.w_pc_incr;
      endcase
   end


   //+--------------------------------------------------------------+//
   //|                        Spec Assertions                       |//
   //+--------------------------------------------------------------+//

   `ifdef DESIGNER_ASSERTIONS
      //TODO add assertions
   `endif

   //+--------------------------------------------------------------+//
   //|                        RTL Debug Code                        |//
   //+--------------------------------------------------------------+//

   `ifndef SYNTHESIS
      //Debug code zone -> this will be ignored during Synthesis
      cpu_opcode_t   debug_opcode_f;
      cpu_opcode_t   debug_opcode_d;
      cpu_opcode_t   debug_opcode_e;
      cpu_opcode_t   debug_opcode_m;
      cpu_opcode_t   debug_opcode_w; 
      instr_t        debug_instruction_f;

      assign debug_instruction_f = pfm_rd_instr;
      assign debug_opcode_f = debug_instruction_f.opc;

      always_ff @(posedge sys_clk or negedge sys_rst_n) begin
         if(!sys_rst_n) begin
            debug_opcode_d <= '0;
            debug_opcode_e <= '0;
            debug_opcode_m <= '0;
            debug_opcode_w <= '0;
         end else begin
            debug_opcode_d <= (d_flush) ? '0             :
                              (d_stall) ? debug_opcode_d :
                                          debug_opcode_f ;
            debug_opcode_e <= (e_flush) ? '0 : debug_opcode_d;
            debug_opcode_m <= debug_opcode_e;
            debug_opcode_w <= debug_opcode_m;
         end
      end
   `endif

endmodule : cpu_pipeline_v2