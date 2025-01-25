//######################################## Header ########################################
//# Author: Vlad Rosu                                                                    #
//# Description: Wrapper for Timer module that includes the timer and its control SFRs   #
//########################################################################################

module tmr_32bit_v1 #(
   parameter DATA_WIDTH = 32,
   parameter ADDR_WIDTH = 32,
   parameter BASE_ADDR  =  0,
   parameter N = 32
)(
   //    Input ports definition
   input                      sys_clk,
   input             [4:0]    sys_clk_div, 
   input                      sys_clk_en,
   input                      sys_rst_n,
   input  [ADDR_WIDTH-1:0]    sys_addr,
   input                      sys_wr_en,
   input  [DATA_WIDTH-1:0]    sys_sw_value,
   //    Output ports definition
   output [DATA_WIDTH-1:0]    sfr_rd_dout,
   output                     match0_event,
   output                     match1_event,
   output                     ovf_event
);

   //==========================
   // Packages and defines
   //==========================
   import pkg_sfrs_definition::*;

   //==========================
   // Local Parameters
   //==========================
   localparam logic [ADDR_WIDTH-1:0] TMR_CTRL_ADDR  =          BASE_ADDR;
   localparam logic [ADDR_WIDTH-1:0] TMR_VAL_ADDR   =  TMR_CTRL_ADDR + 4;
   localparam logic [ADDR_WIDTH-1:0] TMR_MVAL0_ADDR =   TMR_VAL_ADDR + 4;
   localparam logic [ADDR_WIDTH-1:0] TMR_MVAL1_ADDR = TMR_MVAL0_ADDR + 4;

   //==========================
   // Wire declarations
   //==========================
   tmr_ctrl_t           tmr_ctrl_sfr_out;
   tmr_val_t            tmr_val_sfr_out;
   tmr_match_val0_t     tmr_mval0_sfr_out;
   tmr_match_val1_t     tmr_mval1_sfr_out;
   tmr_ctrl_t           tmr_ctrl_sfr_rd;
   tmr_val_t            tmr_val_sfr_rd;
   tmr_match_val0_t     tmr_mval0_sfr_rd;
   tmr_match_val1_t     tmr_mval1_sfr_rd;
   tmr_ctrl_t           hw_up_tmr_ctrl;
   tmr_val_t            hw_up_tmr_val;
   tmr_match_val0_t     hw_up_tmr_mval0;
   tmr_match_val1_t     hw_up_tmr_mval1;
   tmr_ctrl_t           hw_val_tmr_ctrl;
   tmr_val_t            hw_val_tmr_val;
   tmr_match_val0_t     hw_val_tmr_mval0;
   tmr_match_val1_t     hw_val_tmr_mval1;
   logic                tmr_clk;

   //==========================
   // SFR Instances
   //==========================
   sfr_module_v1 #(
      .SFR_ADDR_WIDTH(ADDR_WIDTH),
      .SFR_WIDTH(DATA_WIDTH),
      .SFR_ADDRESS(TMR_CTRL_ADDR),
      .IMPLEMENTED_BITS_MASK(32'h00E0_E7CF),
      .READABLE_BITS_MASK(32'h00E0_E701),
      .SW_UPDATABLE_BITS_MASK(32'h00E0_E7CF),
      .HW_UPDATABLE_BITS_MASK(32'h0000_E0CE)
   ) tmr_ctrl_sfr(
      //    Input ports
      .sys_clk          ( sys_clk            ),
      .sys_clk_en       ( sys_clk_en         ),
      .sys_rst_n        ( sys_rst_n          ),
      .sys_addr         ( sys_addr           ),
      .sys_wr_en        ( sys_wr_en          ),
      .sfr_hw_upate     ( hw_up_tmr_ctrl     ),
      .sfr_hw_value     ( hw_val_tmr_ctrl    ),
      .sfr_sw_value     ( sys_sw_value       ),
      //    Output ports
      .sfr_dout         ( tmr_ctrl_sfr_out   ),
      .sfr_rdonly_dout  ( tmr_ctrl_sfr_rd    )
   );

   sfr_module_v1 #(
      .SFR_ADDR_WIDTH(ADDR_WIDTH),
      .SFR_WIDTH(DATA_WIDTH),
      .SFR_ADDRESS(TMR_VAL_ADDR),
      .IMPLEMENTED_BITS_MASK(32'hFFFF_FFFF),
      .READABLE_BITS_MASK(32'hFFFF_FFFF),
      .SW_UPDATABLE_BITS_MASK(32'hFFFF_FFFF),
      .HW_UPDATABLE_BITS_MASK(32'hFFFF_FFFF)
   ) tmr_val_sfr(
      //    Input ports
      .sys_clk          ( sys_clk            ),
      .sys_clk_en       ( sys_clk_en         ),
      .sys_rst_n        ( sys_rst_n          ),
      .sys_addr         ( sys_addr           ),
      .sys_wr_en        ( sys_wr_en          ),
      .sfr_hw_upate     ( hw_up_tmr_val      ),
      .sfr_hw_value     ( hw_val_tmr_val     ),
      .sfr_sw_value     ( sys_sw_value       ),
      //    Output ports
      .sfr_dout         ( tmr_val_sfr_out    ),
      .sfr_rdonly_dout  ( tmr_val_sfr_rd     )
   );

   sfr_module_v1 #(
      .SFR_ADDR_WIDTH(ADDR_WIDTH),
      .SFR_WIDTH(DATA_WIDTH),
      .SFR_ADDRESS(TMR_MVAL0_ADDR),
      .IMPLEMENTED_BITS_MASK(32'hFFFF_FFFF),
      .READABLE_BITS_MASK(32'hFFFF_FFFF),
      .SW_UPDATABLE_BITS_MASK(32'hFFFF_FFFF),
      .HW_UPDATABLE_BITS_MASK(32'h0000_0000)
   ) tmr_mval0_sfr(
      //    Input ports
      .sys_clk          ( sys_clk            ),
      .sys_clk_en       ( sys_clk_en         ),
      .sys_rst_n        ( sys_rst_n          ),
      .sys_addr         ( sys_addr           ),
      .sys_wr_en        ( sys_wr_en          ),
      .sfr_hw_upate     ( hw_up_tmr_mval0    ),
      .sfr_hw_value     ( hw_val_tmr_mval0   ),
      .sfr_sw_value     ( sys_sw_value       ),
      //    Output ports
      .sfr_dout         ( tmr_mval0_sfr_out  ),
      .sfr_rdonly_dout  ( tmr_mval0_sfr_rd   )
   );

   sfr_module_v1 #(
      .SFR_ADDR_WIDTH(ADDR_WIDTH),
      .SFR_WIDTH(DATA_WIDTH),
      .SFR_ADDRESS(TMR_MVAL1_ADDR),
      .IMPLEMENTED_BITS_MASK(32'hFFFF_FFFF),
      .READABLE_BITS_MASK(32'hFFFF_FFFF),
      .SW_UPDATABLE_BITS_MASK(32'hFFFF_FFFF),
      .HW_UPDATABLE_BITS_MASK(32'h0000_0000)
   ) tmr_mval1_sfr(
      //    Input ports
      .sys_clk          ( sys_clk            ),
      .sys_clk_en       ( sys_clk_en         ),
      .sys_rst_n        ( sys_rst_n          ),
      .sys_addr         ( sys_addr           ),
      .sys_wr_en        ( sys_wr_en          ),
      .sfr_hw_upate     ( hw_up_tmr_mval1    ),
      .sfr_hw_value     ( hw_val_tmr_mval1   ),
      .sfr_sw_value     ( sys_sw_value       ),
      //    Output ports
      .sfr_dout         ( tmr_mval1_sfr_out  ),
      .sfr_rdonly_dout  ( tmr_mval1_sfr_rd   )
   );
   
   //==========================
   // Timer Instance
   //==========================

   //Clock selector
   always_comb begin
      tmr_clk = sys_clk;
      case (tmr_ctrl_sfr_out.clksrc)
         3'b000: tmr_clk = sys_clk;        //sys_clk
         3'b001: tmr_clk = sys_clk_div[0]; //sys_clk_div2
         3'b010: tmr_clk = sys_clk_div[1]; //sys_clk_div4
         3'b011: tmr_clk = sys_clk_div[2]; //sys_clk_div8
         3'b100: tmr_clk = sys_clk_div[3]; //sys_clk_div16
         3'b101: tmr_clk = sys_clk_div[4]; //dco_clk
      endcase
   end

   timer_nbit_v1 #(
      .DATA_WIDTH(DATA_WIDTH),
      .N(N)
   ) tmr_32bit(
      //    Input ports definition
      .sys_clk                ( tmr_clk            ),
      .sys_clk_en             ( sys_clk_en         ),
      .sys_rst_n              ( sys_rst_n          ),
      .tmr_ctrl               ( tmr_ctrl_sfr_out   ),
      .tmr_val                ( tmr_val_sfr_out    ),
      .tmr_match_val0         ( tmr_mval0_sfr_out  ),
      .tmr_match_val1         ( tmr_mval1_sfr_out  ), 
      //    Output ports definition
      .hw_up_tmr_ctrl         ( hw_up_tmr_ctrl     ),
      .hw_up_tmr_val          ( hw_up_tmr_val      ),
      .hw_up_tmr_match_val0   ( hw_up_tmr_mval0    ),
      .hw_up_tmr_match_val1   ( hw_up_tmr_mval1    ),
      .hw_val_tmr_ctrl        ( hw_val_tmr_ctrl    ),
      .hw_val_tmr_val         ( hw_val_tmr_val     ),
      .hw_val_tmr_match_val0  ( hw_val_tmr_mval0   ),
      .hw_val_tmr_match_val1  ( hw_val_tmr_mval1   ),
      .match0_event           ( match0_event       ),
      .match1_event           ( match1_event       ),
      .ovf_event              ( ovf_event          ) 
   );

   //SFR Read output is using wired OR logic because only one SFR should output data based on the sys_addr
   assign sfr_rd_dout = tmr_ctrl_sfr_rd | tmr_val_sfr_rd | tmr_mval0_sfr_rd | tmr_mval1_sfr_rd;

endmodule : tmr_32bit_v1