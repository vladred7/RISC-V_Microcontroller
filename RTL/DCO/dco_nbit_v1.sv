//######################################## Header ########################################
//# Author: Vlad Rosu                                                                    #
//# Description: Top module of the Digital Controlled Oscillator with a resolution of N  #
//#              bits                                                                    #
//########################################################################################

module dco_nbit_v1 #(
   parameter DATA_WIDTH = 32,
   parameter N = 20
)(
   //    Input ports definition
   input                      sys_clk,
   input                      sys_clk_en,
   input                      sys_rst_n,
   input  [DATA_WIDTH-1:0]    dco_ctrl,
   input  [DATA_WIDTH-1:0]    dco_cnt,
   //    Output ports definition
   output [DATA_WIDTH-1:0]    hw_up_dco_ctrl,
   output [DATA_WIDTH-1:0]    hw_up_dco_cnt,
   output [DATA_WIDTH-1:0]    hw_val_dco_ctrl,
   output [DATA_WIDTH-1:0]    hw_val_dco_cnt,
   output                     dco_clk_out
);

   //==========================
   // Packages and defines
   //==========================
   import pkg_sfrs_definition::*;

   //==========================
   // Wire declarations
   //==========================
   dco_ctrl_t           dco_ctrl_reg;
   dco_cnt_t            dco_cnt_reg;
   dco_ctrl_t           dco_hw_up_ctrl;
   dco_cnt_t            dco_hw_up_cnt;
   dco_ctrl_t           dco_hw_val_ctrl;
   dco_cnt_t            dco_hw_val_cnt;
   logic                dco_clk;
   logic [N-1:0]        counter_comb;
   logic [N-1:0]        counter;
   logic                toggle;

   //==========================
   // Flip-flop declarations
   //==========================
   logic                sys_clk_en_sync;
   logic [N-1:0]        counter_ff;
   logic                dco_clk_out_ff;
   
//TODO CLOCK SELECTION LOGIC BASE ON clk src bits in SFR (should I do this logic on the top module?)
   //==========================
   // Input Clock Gate Logic
   //==========================
   //Gate the clock if chip low power mode is enabled or if the module is disabled
   always_ff @(negedge sys_clk) sys_clk_en_sync <= sys_clk_en & dco_ctrl_reg.on; //Sample clock enable on the negedge of the clock to avoid glitches
   assign dco_clk = sys_clk & sys_clk_en_sync;

   //==========================
   // DCO Logic
   //==========================
   assign dco_ctrl_reg = dco_ctrl;
   assign dco_cnt_reg  = dco_cnt;

   assign counter_comb = (toggle) ? '0 : (counter + 1'b1);

   always_ff @(posedge dco_clk or negedge sys_rst_n) begin
      if(!sys_rst_n) begin
         counter_ff <= '0;
      end else begin
         counter_ff <= counter_comb;
      end
   end

   assign counter = counter_ff;
   assign toggle  = (counter == dco_cnt_reg.dcnt);

   always_ff @(posedge dco_clk or negedge sys_rst_n) begin
      if(!sys_rst_n) begin
         dco_clk_out_ff <= '0;
      end else if(toggle) begin
         dco_clk_out_ff <= !dco_clk_out;
      end
   end

   assign dco_clk_out = dco_clk_out_ff;

   //==========================
   //Hardware update bit fields logic
   //==========================
   always_comb begin
      //By default tie the wires to 0's
      dco_hw_up_ctrl  = '0;
      dco_hw_up_cnt   = '0;
      dco_hw_val_ctrl = '0;
      dco_hw_val_cnt  = '0;
   end

   assign hw_up_dco_ctrl  = dco_hw_up_ctrl;
   assign hw_up_dco_cnt   = dco_hw_up_cnt;
   assign hw_val_dco_ctrl = dco_hw_val_ctrl;
   assign hw_val_dco_cnt  = dco_hw_val_cnt;

   //==========================
   // Spec Assertions
   //==========================

   `ifdef DESIGNER_ASSERTIONS
      //TODO add assertions
   `endif

endmodule : dco_nbit_v1