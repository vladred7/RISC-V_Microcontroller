//######################################## Header ########################################
//# Author: Vlad Rosu                                                                    #
//# Description: Module containing logic of the Timer n bit, this will be used as a n bit#
//#              resolution timer with trigger and interrupt signal generation           #
//########################################################################################

module timer_nbit_v1 #(
   parameter DATA_WIDTH = 32,
   parameter N = 32
)(
   //    Input ports definition
   input                      sys_clk,
   input                      sys_clk_en,
   input                      sys_rst_n,
   input  [DATA_WIDTH-1:0]    tmr_ctrl,
   input  [DATA_WIDTH-1:0]    tmr_val,
   input  [DATA_WIDTH-1:0]    tmr_match_val0,
   input  [DATA_WIDTH-1:0]    tmr_match_val1,
   //    Output ports definition
   output [DATA_WIDTH-1:0]    hw_up_tmr_ctrl,
   output [DATA_WIDTH-1:0]    hw_up_tmr_val,
   output [DATA_WIDTH-1:0]    hw_up_tmr_match_val0,
   output [DATA_WIDTH-1:0]    hw_up_tmr_match_val1,
   output [DATA_WIDTH-1:0]    hw_val_tmr_ctrl,
   output [DATA_WIDTH-1:0]    hw_val_tmr_val,
   output [DATA_WIDTH-1:0]    hw_val_tmr_match_val0,
   output [DATA_WIDTH-1:0]    hw_val_tmr_match_val1,
   output                     match0_event,     //TODO: should this be persistent?
   output                     match1_event,     //TODO: should this be persistent?
   output                     ovf_event         //TODO: should this be persistent?
);

   //==========================
   // Packages and defines
   //==========================
   import pkg_sfrs_definition::*;
   
   //==========================
   // Wire declarations
   //==========================
   tmr_ctrl_t           tmr_ctrl_reg;
   tmr_val_t            tmr_val_reg;
   tmr_match_val0_t     tmr_match_val0_reg;
   tmr_match_val1_t     tmr_match_val1_reg;
   tmr_ctrl_t           tmr_hw_up_ctrl;
   tmr_val_t            tmr_hw_up_val;
   tmr_match_val0_t     tmr_hw_up_match_val0;
   tmr_match_val1_t     tmr_hw_up_match_val1;
   tmr_ctrl_t           tmr_hw_val_ctrl;
   tmr_val_t            tmr_hw_val_val;
   tmr_match_val0_t     tmr_hw_val_match_val0;
   tmr_match_val1_t     tmr_hw_val_match_val1;
   logic                tmr_rst_dly;
   logic                tmr_ld_dly;
   logic                tmr_clk;
   logic   [N:0]        tmr_value_comb;         //Timer value combo has 1 more MSbit for OVF detection
   logic [N-1:0]        tmr_value;
   logic                count_en_comb;
   logic                count_en;
   
   //==========================
   // Flip-flop declarations
   //==========================
   logic                sys_clk_en_sync;
   logic                tmr_rst_dly_ff;
   logic                tmr_ld_dly_ff;
   logic [N-1:0]        tmr_value_ff;
   logic                count_en_ff;
   logic                match0_ff;
   logic                match1_ff;
   logic                ovf_ff;

   //==========================
   // Sample fast signals in the tmr clock domain
   //==========================
   always_ff @(posedge tmr_clk or negedge sys_rst_n) begin
      if(!sys_rst_n) begin
         tmr_rst_dly_ff <= 1'b0;
         tmr_ld_dly_ff  <= 1'b0;
      end else begin
         tmr_rst_dly_ff <= tmr_ctrl_reg.rst;
         tmr_ld_dly_ff  <= tmr_ctrl_reg.ld;
      end
   end

   assign tmr_rst_dly = tmr_rst_dly_ff;
   assign tmr_ld_dly  = tmr_ld_dly_ff;

   //==========================
   // Input Clock Gate Logic
   //==========================
   //Gate the clock if chip low power mode is enabled or if the module is disabled
   always_ff @(negedge sys_clk) sys_clk_en_sync <= sys_clk_en & tmr_ctrl_reg.on; //Sample clock enable on the negedge of the clock to avoid glitches
   assign tmr_clk = sys_clk & sys_clk_en_sync;

   //==========================
   //Timer Logic
   //==========================
   assign tmr_ctrl_reg = tmr_ctrl;
   assign tmr_val_reg = tmr_val;
   assign tmr_match_val0_reg = tmr_match_val0;   
   assign tmr_match_val1_reg = tmr_match_val1;

   //Count enable signal logic
   always_comb begin
      count_en_comb = '0;
      case ({tmr_ctrl_reg.start, tmr_ctrl_reg.stop})
         2'b00: count_en_comb = count_en_ff; //Start = 0, Stop = 0 -> Timer Keep current state
         2'b01: count_en_comb = 1'b0;        //Start = 0, Stop = 1 -> Timer Stops
         2'b10: count_en_comb = 1'b1;        //Start = 1, Stop = 0 -> Timer Starts
         2'b11: count_en_comb = 1'b0;        //Start = 1, Stop = 1 -> Timer Stops
      endcase
   end

   always_ff @(posedge tmr_clk or negedge sys_rst_n) begin
      if(!sys_rst_n) begin
         count_en_ff <= 0;
      end else begin
         count_en_ff <= count_en_comb;
      end
   end
   //Or between original value and flopped value to avoid delaying the operation by one tmr_clk
   assign count_en = count_en_ff | count_en_comb;

   //Timer Value Flop and combo logic
   always_comb begin
      if(tmr_rst_dly)                  //Reset Timer value
         tmr_value_comb = '0;
      else if(tmr_ld_dly)              //Load Timer value from register
         tmr_value_comb = tmr_val_reg.tmr_val;
      else if(count_en)                //Enable Timer to count
         tmr_value_comb = tmr_value + 1'b1;
      else                             //Timer retain value
         tmr_value_comb = tmr_value;
   end

   always_ff @(posedge tmr_clk or negedge sys_rst_n) begin
      if(!sys_rst_n) begin
         tmr_value_ff <= '0;
      end else begin
         tmr_value_ff <= tmr_value_comb;
      end
   end

   assign tmr_value = tmr_value_ff;

   //Timer events logic
   assign match0  = (tmr_value == tmr_match_val0_reg.tmr_mch_val0);
   assign match1  = (tmr_value == tmr_match_val1_reg.tmr_mch_val1);
   assign ovf     = tmr_value_comb[32];

   always_ff @(posedge tmr_clk or negedge sys_rst_n) begin
      if(!sys_rst_n) begin
         match0_ff <= 1'b0;
         match1_ff <= 1'b0;
         ovf_ff    <= 1'b0;
      end else begin
         match0_ff <= match0 & tmr_ctrl_reg.match0_en;
         match1_ff <= match1 & tmr_ctrl_reg.match1_en;
         ovf_ff    <= ovf    & tmr_ctrl_reg.ovf_en; 
      end
   end

   assign match0_event  = match0_ff;
   assign match1_event  = match1_ff;
   assign ovf_event     = ovf_ff;


   //==========================
   //Hardware update bit fields logic
   //==========================
   always_comb begin
      //By default tie the wires to 0's
      tmr_hw_up_ctrl             = '0;
      tmr_hw_up_val              = '0;
      tmr_hw_up_match_val0       = '0;
      tmr_hw_up_match_val1       = '0;
      tmr_hw_val_ctrl            = '0;
      tmr_hw_val_val             = '0;
      tmr_hw_val_match_val0      = '0;
      tmr_hw_val_match_val1      = '0;
      //HW update trigger
         //These signals were delayed to support a lower clock frequency than system
      tmr_hw_up_ctrl.rst         = tmr_rst_dly;
      tmr_hw_up_ctrl.ld          = tmr_ld_dly;
         //Read can be faster then tmr clock domain
      tmr_hw_up_ctrl.rd          = tmr_ctrl_reg.rd;
         //Count_en  is in the tmr domain clock that is slower t han system
      tmr_hw_up_ctrl.stop        = tmr_ctrl_reg.stop & (!count_en);
      tmr_hw_up_ctrl.start       = tmr_ctrl_reg.start & count_en;
         //These events are dependent on the timer clock domain that is always slower than the system.
      tmr_hw_up_ctrl.match0_f    = match0;      
      tmr_hw_up_ctrl.match1_f    = match1;
      tmr_hw_up_ctrl.ovf_f       = ovf;
         //Read can be faster then tmr clock domain
      tmr_hw_up_val.tmr_val      = {(DATA_WIDTH-1){tmr_ctrl_reg.rd}};
      //HW update value
      tmr_hw_val_ctrl.rst        = 1'b0;        //HC
      tmr_hw_val_ctrl.ld         = 1'b0;        //HC
      tmr_hw_val_ctrl.rd         = 1'b0;        //HC
      tmr_hw_val_ctrl.stop       = 1'b0;        //HC
      tmr_hw_val_ctrl.start      = 1'b0;        //HC
      tmr_hw_val_ctrl.match0_f   = 1'b1;        //HS
      tmr_hw_val_ctrl.match1_f   = 1'b1;        //HS
      tmr_hw_val_ctrl.ovf_f      = 1'b1;        //HS
      tmr_hw_val_val.tmr_val     = tmr_value;   //HS/HC
   end

   //Assign the HW update output ports
   assign hw_up_tmr_ctrl        = tmr_hw_up_ctrl;
   assign hw_up_tmr_val         = tmr_hw_up_val;
   assign hw_up_tmr_match_val0  = tmr_hw_up_match_val0;
   assign hw_up_tmr_match_val1  = tmr_hw_up_match_val1;
   assign hw_val_tmr_ctrl       = tmr_hw_val_ctrl;
   assign hw_val_tmr_val        = tmr_hw_val_val;
   assign hw_val_tmr_match_val0 = tmr_hw_val_match_val0;
   assign hw_val_tmr_match_val1 = tmr_hw_val_match_val1;


   //==========================
   // Spec Assertions
   //==========================

   `ifdef DESIGNER_ASSERTIONS
      //TODO add assertions
   `endif


endmodule : timer_nbit_v1