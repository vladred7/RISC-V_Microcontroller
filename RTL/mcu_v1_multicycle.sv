//######################################## Header ########################################
//# Author: Vlad Rosu                                                                    #
//# Description: Top file for the multicycle MCU aka v1, containing all modules          #
//########################################################################################

module mcu_v1_multicycle #(
   parameter ADDR_BUS_WIDTH            = 32,
   parameter DATA_BUS_WIDTH            = 32,
   parameter CPU_REG_FILE_ADDR_WIDTH   = 5
)(
   //    Input ports definition
   input                   sys_clk,
   input                   sys_rst_n
);

   //==========================
   // Packages and defines
   //==========================

   //==========================
   // Wire declarations
   //==========================
   logic [ADDR_BUS_WIDTH-1:0] mem_addr;
   logic [DATA_BUS_WIDTH-1:0] mem_data_out;
   logic [DATA_BUS_WIDTH-1:0] mem_data_in;
   logic                      mem_wr_en;
   
   //==========================
   // Flip-flop declarations
   //==========================



   //==========================
   // CPU Instance
   //==========================
   cpu_multicycle_v1 #(
      .ADDR_WIDTH(ADDR_BUS_WIDTH),
      .DATA_WIDTH(DATA_BUS_WIDTH),
      .REG_FILE_ADDR_WIDTH(CPU_REG_FILE_ADDR_WIDTH)
   ) cpu(
      //    Input ports
      .sys_clk        ( sys_clk                    ),
      .sys_rst_n      ( sys_rst_n                  ),
      .mem_data_out   ( mem_data_out               ),
      //    Output ports
      .mem_wr_en      ( mem_wr_en                  ),
      .mem_addr       ( mem_addr                   ),
      .mem_data_in    ( mem_data_in                )
   );

   //==========================
   // Memory Instance
   //==========================
   nvm_mem #(
      .MEM_ADDR_WIDTH(ADDR_BUS_WIDTH),
      .MEM_DATA_WIDTH(DATA_BUS_WIDTH)
   ) memory(
      //    Input ports
      .clk           ( sys_clk                     ),
      .we            ( mem_wr_en                   ),
      .addr          ( mem_addr                    ),
      .wd            ( mem_data_in                 ),
      //    Output ports
      .rd            ( mem_data_out                )
   );

endmodule : mcu_v1_multicycle