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
   fetch_data_path_t    f_stage;          //pipeline data path for Fetch stage
   decode_data_path_t   d_stage;          //pipeline data path for Decode stage
   execute_data_path_t  e_stage;          //pipeline data path for Execute stage
   memory_data_path_t   m_stage;          //pipeline data path for Memory stage
   decode_ctrl_path_t   d_ctrl_stage;     //pipeline control path for Decode stage
   execute_ctrl_path_t  e_ctrl_stage;     //pipeline control path for Execute stage
   memory_ctrl_path_t   m_ctrl_stage;     //pipeline control path for Memory stage
   logic                pc_in_src;        //pc input mux selection
   logic                alu_z_flag;       //alu zero flag

   //==========================
   // Flip-flop declarations
   //==========================
   fetch_data_path_t    f_stage_ff;       //pipeline data path flip flop for Fetch stage
   decode_data_path_t   d_stage_ff;       //pipeline data path flip flop for Decode stage
   execute_data_path_t  e_stage_ff;       //pipeline data path flip flop for Execute stage
   memory_data_path_t   m_stage_ff;       //pipeline data path flip flop for Memory stage
   decode_ctrl_path_t   d_ctrl_stage_ff;  //pipeline control path flip flop for Decode stage
   execute_ctrl_path_t  e_ctrl_stage_ff;  //pipeline control path flip flop for Execute stage
   memory_ctrl_path_t   m_ctrl_stage_ff;  //pipeline control path flip flop for Memory stage

   //+--------------------------------------------------------------+//
   //|                      CPU Control System                      |//
   //+--------------------------------------------------------------+//

   //==========================
   // Control Unit Logic
   //==========================
   cpu_control_unit_v2 ctrl_unit(
      //    Input ports
      .opc           ( f_stage.f_instr.opc         ),
      .funct3        ( f_stage.f_instr.funct3      ),
      .funct7        ( f_stage.f_instr.funct7[5]   ),
      //    Output ports 
      .regfl_wr_en   ( regfl_wr_en                 ),
      .result_src    ( result_src                  ),
      .mem_wr_en     ( mem_wr_en                   ),
      .jmp           ( jmp                         ),
      .bra           ( bra                         ),
      .alu_op_sel    ( alu_op_sel                  ),
      .alu_b_src     ( alu_b_src                   ),
      .imd_src       ( imd_src                     )
   );

   //TODO add hazard clear and reset to the flops

   //Decode Stage
   always_ff @(posedge sys_clk or negedge sys_rst_n) begin
      if(!sys_rst_n) begin
         d_ctrl_stage_ff <= '0;
      end else begin
         d_ctrl_stage_ff.d_regfl_wr_en <= regfl_wr_en;
         d_ctrl_stage_ff.d_result_src  <= result_src;
         d_ctrl_stage_ff.d_mem_wr_en   <= mem_wr_en;
         d_ctrl_stage_ff.d_jmp         <= jmp;
         d_ctrl_stage_ff.d_bra         <= bra;
         d_ctrl_stage_ff.d_alu_op_sel  <= alu_op_sel;
         d_ctrl_stage_ff.d_alu_b_src   <= alu_b_src;
      end
   end

   assign d_ctrl_stage = d_ctrl_stage_ff;

   //Execute Stage
   always_ff @(posedge sys_clk or negedge sys_rst_n) begin
      if(!sys_rst_n) begin
         e_ctrl_stage_ff <= '0;
      end else begin
         e_ctrl_stage_ff.d_regfl_wr_en <= d_ctrl_stage.regfl_wr_en;
         e_ctrl_stage_ff.d_result_src  <= d_ctrl_stage.result_src;
         e_ctrl_stage_ff.d_mem_wr_en   <= d_ctrl_stage.mem_wr_en;
      end
   end

   assign e_ctrl_stage = e_ctrl_stage_ff;

   assign pc_in_src = d_ctrl_stage.d_jmp | (d_ctrl_stage.d_bra & alu_z_flag);

   //Memory Stage
   always_ff @(posedge sys_clk or negedge sys_rst_n) begin
      if(!sys_rst_n) begin
         m_ctrl_stage_ff <= '0;
      end else begin
         m_ctrl_stage_ff.d_regfl_wr_en <= e_ctrl_stage.regfl_wr_en;
         m_ctrl_stage_ff.d_result_src  <= e_ctrl_stage.result_src;
      end
   end

   assign m_ctrl_stage = m_ctrl_stage_ff;

   //==========================
   // Hazard Unit Logic
   //==========================

   //+--------------------------------------------------------------+//
   //|                          Fetch Stage                         |//
   //+--------------------------------------------------------------+//

   //==========================
   // Program Counter Logic
   //==========================
   assign pc_next = pc_in_src ? /*in1*/ : /*in0*/; //TODO

   cpu_program_counter #(
      .ADDR_WIDTH(ADDR_WIDTH)
   ) program_counter(
      //    Input ports
      .clk           ( sys_clk                     ),
      .rst_n         ( sys_rst_n                   ),
      .ld            ( pc_wr_en                    ),
      .pc_in         ( pc_next                     ),
      //    Output ports
      .pc_out        ( pc                          )
   );

   //==========================
   // PFM Logic
   //==========================

   //TODO Memory is now 2 blocks


   

   //+--------------------------------------------------------------+//
   //|                         Decode Stage                         |//
   //+--------------------------------------------------------------+//

   //==========================
   // Register File Logic
   //==========================
   //TODO writes on negedge of sysclk (can write on a result in the first half of cycle and read in the second half) 
   //TODO explicatie daca restul se face pe posedge cand scriu pe negedge voi avea datele imediat la urmatorul posedge ca sa evit hazardele
   cpu_reg_bank #(
      .ADDR_WIDTH(REG_FILE_ADDR_WIDTH),
      .DATA_WIDTH(DATA_WIDTH)
   ) reg_file(
      //    Input ports
      .clk           ( sys_clk                     ),
      .rst_n         ( sys_rst_n                   ),
      .a1            ( instr.instruction.rs1       ),
      .a2            ( instr.instruction.rs2       ),
      .a3            ( instr.instruction.rd        ),
      .wen3          ( regfl_wr_en                 ),
      .wd3           ( result                      ),
      //    Output ports
      .rd1           ( regfl_data_a                ),
      .rd2           ( regfl_data_b                )
   );

   //TODO: signals to PFM

   
   //==========================
   // Sign Extension Logic
   //==========================
   cpu_sign_extend_unit #(
      .DATA_WIDTH(DATA_WIDTH)
   ) sign_ext_unit(
      //    Input ports
      .imd           ( instr.data.imd_data         ),
      .imd_src       ( imd_src                     ),
      //    Output ports
      .imd_ext       ( imd_ext_data                )
   );

   //+--------------------------------------------------------------+//
   //|                         Execute Stage                        |//
   //+--------------------------------------------------------------+//

   //==========================
   // ALU Logic
   //==========================

   cpu_alu #(
      .DATA_WIDTH(DATA_WIDTH)
   ) alu(
      //    Input ports
      .in_a          ( alu_in_a                    ),
      .in_b          ( alu_in_b                    ),
      .op_sel        ( alu_op_sel                  ),
      //    Output ports
      .z_flag        ( alu_z_flag                  ),
      .alu_out       ( alu_out                     )
   );


   //+--------------------------------------------------------------+//
   //|                         Memory Stage                         |//
   //+--------------------------------------------------------------+//
   //TODO signals to DFM
   //==========================
   // DFM Logic
   //==========================


   //+--------------------------------------------------------------+//
   //|                       Write Back Stage                       |//
   //+--------------------------------------------------------------+//



   //==========================
   // Spec Assertions
   //==========================

   `ifdef DESIGNER_ASSERTIONS
      //TODO add assertions
   `endif

endmodule : cpu_pipeline_v2