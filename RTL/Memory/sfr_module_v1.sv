//######################################## Header ########################################
//# Author: Vlad Rosu                                                                    #
//# Description: Top module of the Special Function Register module which is a type of   #
//#              register used for the control of different chip modules that support    #
//#              different types of acceses and udates                                   #
//########################################################################################

module sfr_module_v1 #(
   //TODO This can have a reset value mask parameter if any of the field will need this feature
   parameter SFR_ADDR_WIDTH         = 32,
   parameter SFR_WIDTH              = 32,
   parameter SFR_ADDRESS            = 0,
   parameter IMPLEMENTED_BITS_MASK  = 0,
   parameter READABLE_BITS_MASK     = 0,
   parameter SW_UPDATABLE_BITS_MASK = 0,
   parameter HW_UPDATABLE_BITS_MASK = 0
)(
   //    Input ports definition
   input                         sys_clk,
   input                         sys_clk_en,
   input                         sys_rst_n,
   input  [SFR_ADDR_WIDTH-1:0]   sys_addr,         //Address bus from CPU
   input                         sys_wr_en,        //Write enable from CPU
   input  [SFR_WIDTH-1:0]        sfr_hw_upate,     //HW write enable for specific bit
   input  [SFR_WIDTH-1:0]        sfr_hw_value,     //HW write value for specific bits
   input  [SFR_WIDTH-1:0]        sfr_sw_value,     //SW write value
   //    Output ports definition
   output [SFR_WIDTH-1:0]        sfr_dout,
   output [SFR_WIDTH-1:0]        sfr_rdonly_dout
);

   //==========================
   // Wire declarations
   //==========================
   logic                   sfr_clk;
   logic [SFR_WIDTH-1:0]   sfr_value_ff;
   logic [SFR_WIDTH-1:0]   hw_up;
   logic [SFR_WIDTH-1:0]   sfr_din;
   logic                   sfr_wen;
   logic [SFR_WIDTH-1:0]   sw_up;

   //==========================
   // Flip-flop declarations
   //==========================
   logic                   sys_clk_en_sync;
   logic [SFR_WIDTH-1:0]   sfr_value_ff;

   //==========================
   // Input Clock Gate Logic
   //==========================

   always_ff @(negedge sys_clk) sys_clk_en_sync <= sys_clk_en; //Sample clock enable on the negedge of the clock to avoid glitches
   assign sfr_clk = sys_clk & sys_clk_en_sync;

   //==========================
   // SFR Logic
   //==========================

   //rden signal is generated based on the address of the SFR (specified as a parameter) in the register map
   assign sfr_rden = (sys_addr == SFR_ADDRESS);
   //wen signal is generated based rden and the wr_en from CPU
   assign sfr_wen = sfr_rden & sys_wr_en;

   //Hardware has priority over software for write operations
   always_comb begin
      hw_up = (sfr_hw_upate & HW_UPDATABLE_BITS_MASK);
      sw_up = SW_UPDATABLE_BITS_MASK;
      for (int i = 0; i < SFR_WIDTH; i++) begin
         sfr_din[i] = (          hw_up[i]) ? sfr_hw_value[i]:
                      (sw_up[i] & sfr_wen) ? sfr_sw_value[i]:
                                             sfr_value_ff[i];
      end
   end
   
   always_ff @(posedge sfr_clk or negedge sys_rst_n) begin
      if(!sys_rst_n) begin
         sfr_value_ff <= '0;
      end else begin
         sfr_value_ff <= sfr_din & IMPLEMENTED_BITS_MASK;
      end
   end

   //All SFR outputs will be gated by enable because in the register map they will be ored together
   //assign sfr_dout = (sfr_rden) ? sfr_value_ff : '0; //TODO bug this should not be gated but may need to add another output for the system
   assign sfr_dout = sfr_value_ff;
   assign sfr_rdonly_dout = (sfr_rden) ? (sfr_value_ff & READABLE_BITS_MASK) : '0;

   //==========================
   // Spec Assertions
   //==========================

   `ifdef DESIGNER_ASSERTIONS
      //TODO add assertions
   `endif

endmodule : sfr_module_v1