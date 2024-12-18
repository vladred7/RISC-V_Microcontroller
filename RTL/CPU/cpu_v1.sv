module cpu_v1 #(
   parameter ADDR_WIDTH          = 32,
   parameter DATA_WIDTH          = 32,
   parameter REG_FILE_ADDR_WIDTH = 5
)(
	input sys_clk,
   input sys_rst_n
	
);

   //==========================
   // Packages and defines
   //==========================
   import pkg_cpu_typedefs::*;

   //==========================
   // Wire declarations
   //==========================
   logic [ADDR_WIDTH-1:0] pc;
   logic [ADDR_WIDTH-1:0] pc_next;
   logic [ADDR_WIDTH-1:0] pc_prev;
   logic                  pc_wr_en;
   logic [ADDR_WIDTH-1:0] mem_addr;
   logic [DATA_WIDTH-1:0] mem_data_out;
   logic [DATA_WIDTH-1:0] mem_data_in;
   logic                  mem_addr_src;
   logic                  mem_wr_en;
   logic                  instr_wr_en;
   instr_reg_t            instr;
   logic [DATA_WIDTH-1:0] data;
   logic [DATA_WIDTH-1:0] result;
   logic [           1:0] result_src;
   logic [DATA_WIDTH-1:0] alu_in_a;
   logic [DATA_WIDTH-1:0] alu_in_b;
   logic [DATA_WIDTH-1:0] alu_out;
   logic [DATA_WIDTH-1:0] alu_result;
   logic [           2:0] alu_op_sel;
   logic [           1:0] alu_a_src;
   logic [           1:0] alu_b_src;
   logic                  alu_z_flag;
   logic [           1:0] imd_src;
   logic [DATA_WIDTH-1:0] imd_ext_data;
   logic                  regfl_wr_en;
   logic [DATA_WIDTH-1:0] regfl_data_a;
   logic [DATA_WIDTH-1:0] regfl_data_b;
   logic [DATA_WIDTH-1:0] data_a;
   logic [DATA_WIDTH-1:0] data_b;

   //==========================
   // Flip-flop declarations
   //==========================
   logic [ADDR_WIDTH-1:0] pc_prev_ff;
   logic [DATA_WIDTH-1:0] instr_ff;
   logic [DATA_WIDTH-1:0] data_ff;
   logic [DATA_WIDTH-1:0] data_a_ff;
   logic [DATA_WIDTH-1:0] data_b_ff;
   logic [DATA_WIDTH-1:0] alu_result_ff;

   //==========================
   // Program Counter Logic
   //==========================
   assign pc_next = result;

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

   always_ff @(posedge sys_clk or negedge sys_rst_n) begin
      if(!sys_rst_n) begin
         pc_prev_ff <= '0;
      end else begin //FIXME : Do i need to capture this only in FETCH? might need to add the instr_wr_en here too!
         pc_prev_ff <= pc;
      end
   end

   assign pc_prev = pc_prev_ff;

   //==========================
   // Memory Logic - TODO move this logic on the chip level hierarchy
   //==========================
   assign mem_addr = (mem_addr_src) ? result : pc;
   assign mem_data_in = data_b;

   nvm_mem #(
      .MEM_ADDR_WIDTH(ADDR_WIDTH),
      .MEM_DATA_WIDTH(DATA_WIDTH)
   ) memory(
      //    Input ports
      .clk           ( sys_clk                     ),
      .we            ( mem_wr_en                   ),
      .addr          ( mem_addr                    ),
      .wd            ( mem_data_in                 ),
      //    Output ports
      .rd            ( mem_data_out                )
   );

   always_ff @(posedge sys_clk or negedge sys_rst_n) begin
      if(!sys_rst_n) begin
         instr_ff <= '0;
      end else begin
         instr_ff <= mem_data_out;
      end
   end

   assign instr = instr_ff;

   always_ff @(posedge sys_clk or negedge sys_rst_n) begin
      if(!sys_rst_n) begin
         data_ff <= '0;
      end else begin
         data_ff <= mem_data_out;
      end
   end

   assign data = data_ff;

   //==========================
   // Control Unit FSM Logic
   //==========================
   cpu_control_unit ctrl_unit(
      //    Input ports
      .clk           ( sys_clk                     ),
      .rst_n         ( sys_rst_n                   ),
      .opc           ( instr.instruction.opc       ),
      .funct3        ( instr.instruction.funct3    ),
      .funct7        ( instr.instruction.funct7[5] ),
      .z_flag        ( alu_z_flag ),
      //    Output ports 
      .pc_wr_en      ( pc_wr_en                    ),
      .mem_addr_src  ( mem_addr_src                ),
      .mem_wr_en     ( mem_wr_en                   ),
      .instr_wr_en   ( instr_wr_en                 ),
      .regfl_wr_en   ( regfl_wr_en                 ),
      .imd_src       ( imd_src                     ),
      .alu_a_src     ( alu_a_src                   ),
      .alu_b_src     ( alu_b_src                   ),
      .alu_op_sel    ( alu_op_sel                  ),
      .result_src    ( result_src                  ) 
   );

   //==========================
   // Register File Logic
   //==========================
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

   always_ff @(posedge sys_clk or negedge sys_rst_n) begin
      if(!sys_rst_n) begin
         data_a_ff <= '0;
      end else begin
         data_a_ff <= regfl_data_a;
      end
   end

   assign data_a = data_a_ff;

   always_ff @(posedge sys_clk or negedge sys_rst_n) begin
      if(!sys_rst_n) begin
         data_b_ff <= '0;
      end else begin
         data_b_ff <= regfl_data_b;
      end
   end

   assign data_b = data_b_ff;
   
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

   //==========================
   // ALU Logic
   //==========================
   always_comb begin
      alu_in_a = '0;
      case (alu_a_src)
         2'b00: alu_in_a = pc;
         2'b01: alu_in_a = pc_prev;
         2'b10: alu_in_a = data_a;
      endcase
   end

   always_comb begin
      alu_in_b = '0;
      case (alu_b_src)
         2'b00: alu_in_b = data_b;
         2'b01: alu_in_b = imd_ext_data;
         2'b10: alu_in_b = 4;             //value increment for PC
      endcase
   end

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

   always_ff @(posedge sys_clk or negedge sys_rst_n) begin
      if(!sys_rst_n) begin
         alu_result_ff <= 0;
      end else begin
         alu_result_ff <= alu_out;
      end
   end

   assign alu_result = alu_result_ff;

   always_comb begin
      result = '0;
      case (result_src)
         2'b00: result = alu_result;   //ALU Flopped Result
         2'b01: result = data;         //Data Flopped from Memory
         2'b10: result = alu_out;      //ALU Combinational Result
      endcase
   end

   //==========================
   // Spec Assertions
   //==========================

   `ifdef DESIGNER_ASSERTIONS
      //TODO add assertions
   `endif

endmodule : cpu_v1