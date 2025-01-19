//######################################## Header ########################################
//# Author: Vlad Rosu                                                                    #
//# Description: Wrapper for DCO module that includes the DCO core and its control SFRs  #
//########################################################################################

module dco_20bit_v1 #(
   parameter DATA_WIDTH = 32,
   parameter ADDR_WIDTH = 32,
   parameter BASE_ADDR  =  0,
   parameter N = 20
)(
   //    Input ports definition
   input                      sys_clk,
   input             [3:0]    sys_clk_div,
   input                      sys_clk_en,
   input                      sys_rst_n,
   input  [ADDR_WIDTH-1:0]    sys_addr,
   input                      sys_wr_en,
   input  [DATA_WIDTH-1:0]    sys_sw_value,
   //    Output ports definition
   output [DATA_WIDTH-1:0]    sfr_rd_dout,
   output                     dco_clk_out
);

   //==========================
   // Packages and defines
   //==========================
   import pkg_sfrs_definition::*;

   //==========================
   // Local Parameters
   //==========================
   localparam logic [ADDR_WIDTH-1:0] DCO_CTRL_ADDR =         BASE_ADDR;
   localparam logic [ADDR_WIDTH-1:0] DCO_CNT_ADDR  = DCO_CTRL_ADDR + 4;

   //==========================
   // Wire declarations
   //==========================
   dco_ctrl_t           dco_ctrl_sfr_out;
   dco_cnt_t            dco_cnt_sfr_out;
   dco_ctrl_t           dco_ctrl_sfr_rd;
   dco_cnt_t            dco_cnt_sfr_rd;
   dco_ctrl_t           hw_up_dco_ctrl;
   dco_cnt_t            hw_up_dco_cnt;
   dco_ctrl_t           hw_val_dco_ctrl;
   dco_cnt_t            hw_val_dco_cnt;
   logic                dco_clk;

   //==========================
   // SFR Instances
   //==========================
   sfr_module_v1 #(
      .SFR_ADDR_WIDTH(ADDR_WIDTH),
      .SFR_WIDTH(DATA_WIDTH),
      .SFR_ADDRESS(DCO_CTRL_ADDR),
      .IMPLEMENTED_BITS_MASK(32'h0000_0701),
      .READABLE_BITS_MASK(32'h0000_0701),
      .SW_UPDATABLE_BITS_MASK(32'h0000_0701),
      .HW_UPDATABLE_BITS_MASK(32'h0000_0000)
   ) dco_ctrl_sfr(
      //    Input ports
      .sys_clk          ( sys_clk            ),
      .sys_clk_en       ( sys_clk_en         ),
      .sys_rst_n        ( sys_rst_n          ),
      .sys_addr         ( sys_addr           ),
      .sys_wr_en        ( sys_wr_en          ),
      .sfr_hw_upate     ( hw_up_dco_ctrl     ),
      .sfr_hw_value     ( hw_val_dco_ctrl    ),
      .sfr_sw_value     ( sys_sw_value       ),
      //    Output ports
      .sfr_dout         ( dco_ctrl_sfr_out   ),
      .sfr_rdonly_dout  ( dco_ctrl_sfr_rd    )
   );

   sfr_module_v1 #(
      .SFR_ADDR_WIDTH(ADDR_WIDTH),
      .SFR_WIDTH(DATA_WIDTH),
      .SFR_ADDRESS(DCO_CNT_ADDR),
      .IMPLEMENTED_BITS_MASK(32'h000F_FFFF),
      .READABLE_BITS_MASK(32'h000F_FFFF),
      .SW_UPDATABLE_BITS_MASK(32'h000F_FFFF),
      .HW_UPDATABLE_BITS_MASK(32'h0000_0000)
   ) dco_cnt_sfr(
      //    Input ports
      .sys_clk          ( sys_clk            ),
      .sys_clk_en       ( sys_clk_en         ),
      .sys_rst_n        ( sys_rst_n          ),
      .sys_addr         ( sys_addr           ),
      .sys_wr_en        ( sys_wr_en          ),
      .sfr_hw_upate     ( hw_up_dco_cnt      ),
      .sfr_hw_value     ( hw_val_dco_cnt     ),
      .sfr_sw_value     ( sys_sw_value       ),
      //    Output ports
      .sfr_dout         ( dco_cnt_sfr_out    ),
      .sfr_rdonly_dout  ( dco_cnt_sfr_rd     )
   );
   
   //==========================
   // DCO Instance
   //==========================

   //Clock selector
   always_comb begin
      dco_clk = sys_clk;
      case (dco_ctrl_sfr_out.clksrc)
         3'b000: dco_clk = sys_clk;
         3'b001: dco_clk = sys_clk_div[0];
         3'b010: dco_clk = sys_clk_div[1];
         3'b011: dco_clk = sys_clk_div[2];
         3'b100: dco_clk = sys_clk_div[3];
      endcase
   end

   dco_nbit_v1 #(
      .DATA_WIDTH(DATA_WIDTH),
      .N(N)
   ) dco_nbit(
      //    Input ports definition
      .sys_clk          ( dco_clk            ),
      .sys_clk_en       ( sys_clk_en         ),
      .sys_rst_n        ( sys_rst_n          ),
      .dco_ctrl         ( dco_ctrl_sfr_out   ),
      .dco_cnt          ( dco_cnt_sfr_out    ),
      //    Output ports definition
      .hw_up_dco_ctrl   ( hw_up_dco_ctrl     ),
      .hw_up_dco_cnt    ( hw_up_dco_cnt      ),
      .hw_val_dco_ctrl  ( hw_val_dco_ctrl    ),
      .hw_val_dco_cnt   ( hw_val_dco_cnt     ),
      .dco_clk_out      ( dco_clk_out        )
   );

   //SFR Read output is using wired OR logic because only one SFR should output data based on the sys_addr
   assign sfr_rd_dout = dco_ctrl_sfr_rd | dco_cnt_sfr_rd;

endmodule : dco_20bit_v1