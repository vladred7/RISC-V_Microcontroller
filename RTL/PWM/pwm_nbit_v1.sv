//######################################## Header ########################################
//# Author: Vlad Rosu                                                                    #
//# Description: Module containing functionality of the PWM n bit, this module will be   #
//#              used as a n bit resolution generator for a pulse width modulated wave   #
//########################################################################################

module pwm_nbit_v1 #(
   parameter DATA_WIDTH = 32,
   parameter N = 16
)(
   //    Input ports definition
   input                      sys_clk,
   input                      sys_clk_en,
   input                      sys_rst_n,
   input  [DATA_WIDTH-1:0]    pwm_ctrl,
   input  [DATA_WIDTH-1:0]    pwm_tmr,
   input  [DATA_WIDTH-1:0]    pwm_cfg0,
   input  [DATA_WIDTH-1:0]    pwm_cfg1,
   //    Output ports definition
   output [DATA_WIDTH-1:0]    hw_up_pwm_ctrl,
   output [DATA_WIDTH-1:0]    hw_up_pwm_tmr,
   output [DATA_WIDTH-1:0]    hw_up_pwm_cfg0,
   output [DATA_WIDTH-1:0]    hw_up_pwm_cfg1,
   output [DATA_WIDTH-1:0]    hw_val_pwm_ctrl,
   output [DATA_WIDTH-1:0]    hw_val_pwm_tmr,
   output [DATA_WIDTH-1:0]    hw_val_pwm_cfg0,
   output [DATA_WIDTH-1:0]    hw_val_pwm_cfg1,
   output                     pr_match_event,
   output                     dc_match_event,
   output                     ph_match_event,
   output                     of_match_event,
   output                     pwm_out
);

   //==========================
   // Packages and defines
   //==========================
   import pkg_sfrs_definition::*;

   //==========================
   // Wire declarations
   //==========================
   pwm_ctrl_t           pwm_ctrl_reg;
   pwm_tmr_t            pwm_tmr_reg;
   pwm_cfg0_t           pwm_cfg0_reg;
   pwm_cfg1_t           pwm_cfg1_reg;
   pwm_ctrl_t           pwm_hw_up_ctrl;
   pwm_tmr_t            pwm_hw_up_tmr;
   pwm_cfg0_t           pwm_hw_up_cfg0;
   pwm_cfg1_t           pwm_hw_up_cfg1;
   pwm_ctrl_t           pwm_hw_val_ctrl;
   pwm_tmr_t            pwm_hw_val_tmr;
   pwm_cfg0_t           pwm_hw_val_cfg0;
   pwm_cfg1_t           pwm_hw_val_cfg1;
   logic                pwm_rst_dly;
   logic                pwm_ld_dly;
   logic                pwm_ld_trg_dly;
   logic                pwm_clk;
   logic [N-1:0]        shadow_pr;
   logic [N-1:0]        shadow_dc;
   logic [N-1:0]        shadow_ph;
   logic [N-1:0]        shadow_of;
   logic [N-1:0]        pwm_tmr_value_comb;
   logic [N-1:0]        pwm_tmr_value;
   logic                pr_match;
   logic                dc_match;
   logic                ph_match;
   logic                of_match;
   logic                pwm_out_comb;

   //==========================
   // Flip-flop declarations
   //==========================
   logic                sys_clk_en_sync;
   logic                pwm_rst_dly_ff;
   logic                pwm_ld_dly_ff;
   logic                pwm_ld_trg_dly_ff;
   logic [N-1:0]        shadow_pr_ff;
   logic [N-1:0]        shadow_dc_ff;
   logic [N-1:0]        shadow_ph_ff;
   logic [N-1:0]        shadow_of_ff;
   logic [N-1:0]        pwm_tmr_value_ff;
   logic                pr_match_ff;
   logic                dc_match_ff;
   logic                ph_match_ff;
   logic                of_match_ff;
   logic                pwm_out_ff;

   //==========================
   // Input Clock Gate Logic
   //==========================
   //Gate the clock if chip low power mode is enabled or if the module is disabled
   always_ff @(negedge sys_clk) sys_clk_en_sync <= sys_clk_en & pwm_ctrl_reg.on; //Sample clock enable on the negedge of the clock to avoid glitches
   assign pwm_clk = sys_clk & sys_clk_en_sync;


   //==========================
   // Sample fast signals in the pwm clock domain
   //==========================
   always_ff @(posedge pwm_clk or negedge sys_rst_n) begin
      if(!sys_rst_n) begin
         pwm_rst_dly_ff    <= 1'b0;
         pwm_ld_dly_ff     <= 1'b0;
         pwm_ld_trg_dly_ff <= 1'b0;
      end else begin
         pwm_rst_dly_ff    <= pwm_ctrl_reg.rst;
         pwm_ld_dly_ff     <= pwm_ctrl_reg.ld;
         pwm_ld_trg_dly_ff <= pwm_ctrl_reg.ld_trg; //use this signal only as a hwupd clear bit
      end
   end

   assign pwm_rst_dly = pwm_rst_dly_ff;
   assign pwm_ld_dly  = pwm_ld_dly_ff;
   assign pwm_ld_trg_dly  = pwm_ld_trg_dly_ff;


   //==========================
   // PWM Logic
   //==========================
   assign pwm_ctrl_reg = pwm_ctrl;
   assign pwm_tmr_reg  = pwm_tmr;
   assign pwm_cfg0_reg = pwm_cfg0;
   assign pwm_cfg1_reg = pwm_cfg1;

   //Shadow Buffers for the configuration values that are loaded only when ld_trig is set and there is a period match
   always_ff @(posedge pwm_clk or negedge sys_rst_n) begin
      if(!sys_rst_n) begin
         shadow_pr_ff <= '0;
         shadow_dc_ff <= '0;
         shadow_ph_ff <= '0;
         shadow_of_ff <= '0;
      //Load the cfg values into shadows when ld_trig is set at the end of the cycle to avoid glitches
      end else if(pwm_ctrl_reg.ld_trg & pr_match) begin
         shadow_pr_ff <= pwm_cfg0_reg.pr;
         shadow_dc_ff <= pwm_cfg0_reg.dc;
         shadow_ph_ff <= pwm_cfg1_reg.ph;
         shadow_of_ff <= pwm_cfg1_reg.of;
      end
   end

   assign shadow_pr = shadow_pr_ff;
   assign shadow_dc = shadow_dc_ff;
   assign shadow_ph = shadow_ph_ff;
   assign shadow_of = shadow_of_ff;

   //Timer Value Flop and combo logic
   //This does not need a start trigger because the user can set the OEN and RST bits 
   //simultaneously producing a fresh start of the PWM timer
   always_comb begin
      if(pwm_rst_dly | pr_match)             //Reset Timer value
         pwm_tmr_value_comb = '0;
      else if(pwm_ld_dly)                    //Load Timer value from register
         pwm_tmr_value_comb = pwm_tmr_reg.tval;
      else                                   //Timer Increments
         pwm_tmr_value_comb = pwm_tmr_value + 1'b1;
   end

   always_ff @(posedge pwm_clk or negedge sys_rst_n) begin
      if(!sys_rst_n) begin
         pwm_tmr_value_ff <= '0;
      end else begin
         pwm_tmr_value_ff <= pwm_tmr_value_comb;
      end
   end

   assign pwm_tmr_value = pwm_tmr_value_ff;

   //PWM Events Logic //TODO can speed up here
   assign pr_match = (pwm_tmr_value == shadow_pr) & pwm_ctrl_reg.on;
   assign dc_match = (pwm_tmr_value == shadow_dc) & pwm_ctrl_reg.on;
   assign ph_match = (pwm_tmr_value == shadow_ph) & pwm_ctrl_reg.on;
   assign of_match = (pwm_tmr_value == shadow_of) & pwm_ctrl_reg.on;

   always_ff @(posedge pwm_clk or negedge sys_rst_n) begin
      if(!sys_rst_n) begin
         pr_match_ff <= 1'b0;
         dc_match_ff <= 1'b0;
         ph_match_ff <= 1'b0;
         of_match_ff <= 1'b0;
      end else begin
         pr_match_ff <= pr_match;
         dc_match_ff <= dc_match;
         ph_match_ff <= ph_match;
         of_match_ff <= of_match;
      end
   end
   //Output events should be stable
   assign pr_match_event = pr_match_ff & pwm_ctrl_reg.prm_en;
   assign dc_match_event = dc_match_ff & pwm_ctrl_reg.dcm_en;
   assign ph_match_event = ph_match_ff & pwm_ctrl_reg.phm_en;
   assign of_match_event = of_match_ff & pwm_ctrl_reg.ofm_en;
   
   //PWM Output logic
   always_comb begin
      //Reset PWM_OUT value,                 DC<=PH exception out should be 0
      if(pwm_rst_dly | dc_match | (shadow_dc <= shadow_ph))
         pwm_out_comb = 1'b0;
      else if(ph_match)
         pwm_out_comb = 1'b1;
      else
         pwm_out_comb = pwm_out_ff;
   end

   always_ff @(posedge pwm_clk or negedge sys_rst_n) begin
      if(!sys_rst_n) begin
         pwm_out_ff <= '0;
      end else begin
         pwm_out_ff <= pwm_out_comb;
      end
   end

   assign pwm_out = (pwm_out_ff ^ pwm_ctrl_reg.pol) & pwm_ctrl_reg.oen;


   //==========================
   //Hardware update bit fields logic
   //==========================
   always_comb begin
      //By default tie the wires to 0's
      pwm_hw_up_ctrl          = '0;
      pwm_hw_up_tmr           = '0;
      pwm_hw_up_cfg0          = '0;
      pwm_hw_up_cfg1          = '0;
      pwm_hw_val_ctrl         = '0;
      pwm_hw_val_tmr          = '0;
      pwm_hw_val_cfg0         = '0;
      pwm_hw_val_cfg1         = '0;
      //HW update trigger
         //These signals were delayed to support a lower clock frequency than system
      pwm_hw_up_ctrl.rst      = pwm_rst_dly; 
      pwm_hw_up_ctrl.ld       = pwm_ld_dly;
         //Read can be faster then pwm clock domain
      pwm_hw_up_ctrl.rd       = pwm_ctrl_reg.rd;
         //This is dependent on an event in pwm clock domain so if the pwm is slower this still works.
      pwm_hw_up_ctrl.ld_trg   = pwm_ld_trg_dly & pr_match_ff;
         //These events are dependent on the pwm clock domain that is always slower than the system.
      pwm_hw_up_ctrl.prm_f    = pr_match;
      pwm_hw_up_ctrl.dcm_f    = dc_match;
      pwm_hw_up_ctrl.phm_f    = ph_match;
      pwm_hw_up_ctrl.ofm_f    = of_match;
         //Read can be faster then pwm clock domain
      pwm_hw_up_tmr.tval      = {(N){pwm_ctrl_reg.rd}};
      //HW update value
      pwm_hw_val_ctrl.rst     = 1'b0;           //HC
      pwm_hw_val_ctrl.ld      = 1'b0;           //HC
      pwm_hw_val_ctrl.rd      = 1'b0;           //HC
      pwm_hw_val_ctrl.ld_trg  = 1'b0;           //HC
      pwm_hw_val_ctrl.prm_f   = 1'b1;           //HS
      pwm_hw_val_ctrl.dcm_f   = 1'b1;           //HS
      pwm_hw_val_ctrl.phm_f   = 1'b1;           //HS
      pwm_hw_val_ctrl.ofm_f   = 1'b1;           //HS
      pwm_hw_val_tmr.tval     = pwm_tmr_value;  //HS/HC
   end

   assign hw_up_pwm_ctrl  = pwm_hw_up_ctrl;
   assign hw_up_pwm_tmr   = pwm_hw_up_tmr;
   assign hw_up_pwm_cfg0  = pwm_hw_up_cfg0;
   assign hw_up_pwm_cfg1  = pwm_hw_up_cfg1;
   assign hw_val_pwm_ctrl = pwm_hw_val_ctrl;
   assign hw_val_pwm_tmr  = pwm_hw_val_tmr;
   assign hw_val_pwm_cfg0 = pwm_hw_val_cfg0;
   assign hw_val_pwm_cfg1 = pwm_hw_val_cfg1;

   //==========================
   // Spec Assertions
   //==========================

   `ifdef DESIGNER_ASSERTIONS
      //TODO add assertions
   `endif


endmodule : pwm_nbit_v1