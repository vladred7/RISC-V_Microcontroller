//######################################## Header ########################################
//# Author: Vlad Rosu                                                                    #
//# Description: Top module of the clock prescaller module implemented as a synchronous  # 
//#              clock divider for the system                                            #
//########################################################################################

module clk_prescaller_v1 #(
   parameter DIV_RESOLUTION = 4
)(
   //    Input ports definition
   input                         sys_clk,
   input                         sys_clk_en,
   input                         sys_rst_n,
   //    Output ports definition
   output [DIV_RESOLUTION-1:0]   pclk_out
);

   //==========================
   // Wire declarations
   //==========================
   logic                         in_clk;

   //==========================
   // Flip-flop declarations
   //==========================
   logic [DIV_RESOLUTION-1:0]    pclk_out_ff;
   logic                         sys_clk_en_sync;

   //==========================
   // Input Clock Gate Logic
   //==========================

   always_ff @(negedge sys_clk) sys_clk_en_sync <= sys_clk_en; //Sample clock enable on the negedge of the clock to avoid glitches
   assign in_clk = sys_clk & sys_clk_en_sync;

   //==========================
   // Prescaller Logic (Synchronous)
   //==========================

   always_ff @(posedge in_clk or negedge sys_rst_n) begin
      if(!sys_rst_n) begin
         pclk_out_ff <= '0;
      end else begin
         pclk_out_ff <= pclk_out + 1'b1;
      end
   end

   assign pclk_out = pclk_out_ff;
   

   //==========================
   // Spec Assertions
   //==========================

   `ifdef DESIGNER_ASSERTIONS
      //TODO add assertions
   `endif


endmodule : clk_prescaller_v1