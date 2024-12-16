module cpu_v1 #(
   parameter ADDR_WIDTH          = 32,
   parameter DATA_WIDTH          = 32,
   parameter REG_FILE_ADDR_WIDTH = 5
)(
	input sys_clk,
   input sys_rst_n,
	
);

   //==========================
   // Packages and defines
   //==========================
   import pkg_cpu_typedefs::*;

   //==========================
   // Wire declarations
   //==========================



   //==========================
   // Program Counter Logic
   //==========================
   cpu_program_counter #(
      .ADDR_WIDTH(ADDR_WIDTH)
   ) pc(
      //    Input ports
      .clk           (  ),
      .rst_n         (  ),
      .ld            (  ),
      .pc_in         (  ),
      //    Output ports
      .pc_out        (  )
   );

   //==========================
   // Memory Logic
   //==========================

   nvm_mem #(
      .MEM_ADDR_WIDTH(ADDR_WIDTH),
      .MEM_DATA_WIDTH(DATA_WIDTH)
   ) memory(
      //    Input ports
      .clk           (  ),
      .we            (  ),
      .addr          (  ),
      .wd            (  ),
      //    Output ports
      .rd            (  )
   );

   //==========================
   // Control Unit FSM Logic
   //==========================

   cpu_control_unit ctrl_unit(
      //    Input ports
      .clk           (  ),
      .rst_n         (  ),
      .opc           (  ),
      .funct3        (  ),
      .funct7        (  ),
      .z_flag        (  ),
      //    Output ports 
      .pc_wr_en      (  ),
      .mem_addr_src  (  ),
      .mem_wr_en     (  ),
      .instr_wr_en   (  ),
      .result_src    (  ),
      .alu_op_sel    (  ),
      .alu_a_src     (  ),
      .alu_b_src     (  ),
      .imd_src       (  ),
      .regfl_wr_en   (  )
   );

   //==========================
   // Register File Logic
   //==========================

   cpu_reg_bank #(
      .ADDR_WIDTH(REG_FILE_ADDR_WIDTH),
      .DATA_WIDTH(DATA_WIDTH)
   ) reg_file(
      //    Input ports
      .clk           (  ),
      .rst_n         (  ),
      .a1            (  ),
      .a2            (  ),
      .a3            (  ),
      .wen3          (  ),
      .wd3           (  ),
      //    Output ports
      .rd1           (  ),
      .rd2           (  )
   );

   //==========================
   // Sign Extension Logic
   //==========================

   cpu_sign_extend_unit #(
      .DATA_WIDTH(DATA_WIDTH)
   ) sign_ext_unit(
      //    Input ports
      .imd           (  ),
      .imd_src       (  ),
      //    Output ports
      .imd_ext       (  )
   );

   //==========================
   // ALU Logic
   //==========================

   cpu_alu #(
      .DATA_WIDTH(DATA_WIDTH)
   ) alu(
      //    Input ports
      .in_a          (  ),
      .in_b          (  ),
      .op_sel        (  ),
      //    Output ports
      .zero          (  ),
      .alu_out       (  )
   );

endmodule : cpu_v1