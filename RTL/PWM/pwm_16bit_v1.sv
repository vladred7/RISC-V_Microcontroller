//######################################## Header ########################################
//# Author: Vlad Rosu                                                                    #
//# Description: Wrapper for PWM module that includes the PWM core and its control SFRs  #
//########################################################################################

module pwm_16bit_v1 #(
   parameter DATA_WIDTH = 32,
   parameter ADDR_WIDTH = 32,
   parameter BASE_ADDR  =  0,
   parameter N = 16
)(
   //    Input ports definition
   input                      sys_clk,
   input             [3:0]    sys_clk_div,
   input                      sys_clk_en,
   input                      sys_rst_n,
   input  [ADDR_WIDTH-1:0]    sys_addr,         //Address bus from CPU
   input                      sys_wr_en,        //Write enable from CPU
   input  [DATA_WIDTH-1:0]    sys_sw_value,
   //    Output ports definition
   output [DATA_WIDTH-1:0]    sfr_rd_dout,
   output                     pr_event,
   output                     dc_event,
   output                     ph_event,
   output                     of_event,
   output                     pwm_out
);

   //==========================
   // Packages and defines
   //==========================
   import pkg_sfrs_definition::*;

   //==========================
   // Local Parameters
   //==========================
   localparam logic [ADDR_WIDTH-1:0] PWM_CTRL_ADDR =         BASE_ADDR;
   localparam logic [ADDR_WIDTH-1:0] PWM_TMR_ADDR  = PWM_CTRL_ADDR + 4;
   localparam logic [ADDR_WIDTH-1:0] PWM_CFG0_ADDR = PWM_TMR_ADDR  + 4;
   localparam logic [ADDR_WIDTH-1:0] PWM_CFG1_ADDR = PWM_CFG0_ADDR + 4;

   //==========================
   // Wire declarations
   //==========================
   pwm_ctrl_t  pwm_ctrl_sfr_out;
   pwm_tmr_t   pwm_tmr_sfr_out;
   pwm_cfg0_t  pwm_cfg0_sfr_out;
   pwm_cfg1_t  pwm_cfg1_sfr_out;
   pwm_ctrl_t  pwm_ctrl_sfr_rd;
   pwm_tmr_t   pwm_tmr_sfr_rd;
   pwm_cfg0_t  pwm_cfg0_sfr_rd;
   pwm_cfg1_t  pwm_cfg1_sfr_rd;
   pwm_ctrl_t  hw_up_pwm_ctrl;
   pwm_tmr_t   hw_up_pwm_tmr;
   pwm_cfg0_t  hw_up_pwm_cfg0;
   pwm_cfg1_t  hw_up_pwm_cfg1;
   pwm_ctrl_t  hw_val_pwm_ctrl;
   pwm_tmr_t   hw_val_pwm_tmr;
   pwm_cfg0_t  hw_val_pwm_cfg0;
   pwm_cfg1_t  hw_val_pwm_cfg1;
   logic       pr_match_event;
   logic       dc_match_event;
   logic       ph_match_event;
   logic       of_match_event;
   logic       pwm_clk;

   //==========================
   // SFR Instances
   //==========================
   logic [DATA_WIDTH-1:0] sw_so_pwm_ctrl;
   logic [DATA_WIDTH-1:0] sw_val_pwm_ctrl;
   
   //SW Set only bits protection
   assign sw_so_pwm_ctrl  = sys_sw_value | (pwm_ctrl_sfr_out & 32'h0000_001E);
   assign sw_val_pwm_ctrl = sw_so_pwm_ctrl;

   sfr_module_v1 #(
      .SFR_ADDR_WIDTH(ADDR_WIDTH),
      .SFR_WIDTH(DATA_WIDTH),
      .SFR_ADDRESS(PWM_CTRL_ADDR),
      .IMPLEMENTED_BITS_MASK(32'hFF0007DF),
      .READABLE_BITS_MASK(32'hFF0007C1),
      .SW_UPDATABLE_BITS_MASK(32'hFF0007DF),
      .HW_UPDATABLE_BITS_MASK(32'hF000001E)
   ) pwm_ctrl_sfr(
      //    Input ports
      .sys_clk          ( sys_clk            ),
      .sys_clk_en       ( sys_clk_en         ),
      .sys_rst_n        ( sys_rst_n          ),
      .sys_addr         ( sys_addr           ),
      .sys_wr_en        ( sys_wr_en          ),
      .sfr_hw_upate     ( hw_up_pwm_ctrl     ),
      .sfr_hw_value     ( hw_val_pwm_ctrl    ),
      .sfr_sw_value     ( sw_val_pwm_ctrl    ),
      //    Output ports
      .sfr_dout         ( pwm_ctrl_sfr_out   ),
      .sfr_rdonly_dout  ( pwm_ctrl_sfr_rd    )
   );

   sfr_module_v1 #(
      .SFR_ADDR_WIDTH(ADDR_WIDTH),
      .SFR_WIDTH(DATA_WIDTH),
      .SFR_ADDRESS(PWM_TMR_ADDR),
      .IMPLEMENTED_BITS_MASK(32'h0000FFFF),
      .READABLE_BITS_MASK(32'h0000FFFF),
      .SW_UPDATABLE_BITS_MASK(32'h0000FFFF),
      .HW_UPDATABLE_BITS_MASK(32'h0000FFFF)
   ) pwm_tmr_sfr(
      //    Input ports
      .sys_clk          ( sys_clk            ),
      .sys_clk_en       ( sys_clk_en         ),
      .sys_rst_n        ( sys_rst_n          ),
      .sys_addr         ( sys_addr           ),
      .sys_wr_en        ( sys_wr_en          ),
      .sfr_hw_upate     ( hw_up_pwm_tmr      ),
      .sfr_hw_value     ( hw_val_pwm_tmr     ),
      .sfr_sw_value     ( sys_sw_value       ),
      //    Output ports
      .sfr_dout         ( pwm_tmr_sfr_out    ),
      .sfr_rdonly_dout  ( pwm_tmr_sfr_rd     )
   );

   sfr_module_v1 #(
      .SFR_ADDR_WIDTH(ADDR_WIDTH),
      .SFR_WIDTH(DATA_WIDTH),
      .SFR_ADDRESS(PWM_CFG0_ADDR),
      .IMPLEMENTED_BITS_MASK(32'hFFFFFFFF),
      .READABLE_BITS_MASK(32'hFFFFFFFF),
      .SW_UPDATABLE_BITS_MASK(32'hFFFFFFFF),
      .HW_UPDATABLE_BITS_MASK(32'h00000000)
   ) pwm_cfg0_sfr(
      //    Input ports
      .sys_clk          ( sys_clk            ),
      .sys_clk_en       ( sys_clk_en         ),
      .sys_rst_n        ( sys_rst_n          ),
      .sys_addr         ( sys_addr           ),
      .sys_wr_en        ( sys_wr_en          ),
      .sfr_hw_upate     ( hw_up_pwm_cfg0     ),
      .sfr_hw_value     ( hw_val_pwm_cfg0    ),
      .sfr_sw_value     ( sys_sw_value       ),
      //    Output ports
      .sfr_dout         ( pwm_cfg0_sfr_out   ),
      .sfr_rdonly_dout  ( pwm_cfg0_sfr_rd    )
   );

   sfr_module_v1 #(
      .SFR_ADDR_WIDTH(ADDR_WIDTH),
      .SFR_WIDTH(DATA_WIDTH),
      .SFR_ADDRESS(PWM_CFG1_ADDR),
      .IMPLEMENTED_BITS_MASK(32'hFFFFFFFF),
      .READABLE_BITS_MASK(32'hFFFFFFFF),
      .SW_UPDATABLE_BITS_MASK(32'hFFFFFFFF),
      .HW_UPDATABLE_BITS_MASK(32'h00000000)
   ) pwm_cfg1_sfr(
      //    Input ports
      .sys_clk          ( sys_clk            ),
      .sys_clk_en       ( sys_clk_en         ),
      .sys_rst_n        ( sys_rst_n          ),
      .sys_addr         ( sys_addr           ),
      .sys_wr_en        ( sys_wr_en          ),
      .sfr_hw_upate     ( hw_up_pwm_cfg1     ),
      .sfr_hw_value     ( hw_val_pwm_cfg1    ),
      .sfr_sw_value     ( sys_sw_value       ),
      //    Output ports
      .sfr_dout         ( pwm_cfg1_sfr_out   ),
      .sfr_rdonly_dout  ( pwm_cfg1_sfr_rd    )
   );
   
   //==========================
   // PWM Instance
   //==========================

   //Clock selector
   always_comb begin
      pwm_clk = sys_clk;
      case (pwm_ctrl_sfr_out.clksrc)
         3'b000: pwm_clk = sys_clk;
         3'b001: pwm_clk = sys_clk_div[0];
         3'b010: pwm_clk = sys_clk_div[1];
         3'b011: pwm_clk = sys_clk_div[2];
         3'b100: pwm_clk = sys_clk_div[3];
      endcase
   end

   pwm_nbit_v1 #(
      .DATA_WIDTH(DATA_WIDTH),
      .N(N)
   ) pwm_16bit(
      //    Input ports definition
      .sys_clk          ( pwm_clk            ),
      .sys_clk_en       ( sys_clk_en         ),
      .sys_rst_n        ( sys_rst_n          ),
      .pwm_ctrl         ( pwm_ctrl_sfr_out   ),
      .pwm_tmr          ( pwm_tmr_sfr_out    ),
      .pwm_cfg0         ( pwm_cfg0_sfr_out   ),
      .pwm_cfg1         ( pwm_cfg1_sfr_out   ),
      //    Output ports definition
      .hw_up_pwm_ctrl   ( hw_up_pwm_ctrl     ),
      .hw_up_pwm_tmr    ( hw_up_pwm_tmr      ),
      .hw_up_pwm_cfg0   ( hw_up_pwm_cfg0     ),
      .hw_up_pwm_cfg1   ( hw_up_pwm_cfg1     ),
      .hw_val_pwm_ctrl  ( hw_val_pwm_ctrl    ),
      .hw_val_pwm_tmr   ( hw_val_pwm_tmr     ),
      .hw_val_pwm_cfg0  ( hw_val_pwm_cfg0    ),
      .hw_val_pwm_cfg1  ( hw_val_pwm_cfg1    ),
      .pr_match_event   ( pr_match_event     ),
      .dc_match_event   ( dc_match_event     ),
      .ph_match_event   ( ph_match_event     ),
      .of_match_event   ( of_match_event     ),
      .pwm_out          ( pwm_out            )
   ); 

   assign pr_event = pr_match_event;
   assign dc_event = dc_match_event;
   assign ph_event = ph_match_event;
   assign of_event = of_match_event;

   //SFR Read output is using wired OR logic because only one SFR should output data based on the sys_addr
   assign sfr_rd_dout = pwm_ctrl_sfr_rd | pwm_tmr_sfr_rd | pwm_cfg0_sfr_rd | pwm_cfg1_sfr_rd;

endmodule : pwm_16bit_v1