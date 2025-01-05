//######################################## Header ########################################
//# Author: Vlad Rosu                                                                    #
//# Description: This package contains UDTs used to describe the SFR signals             #
//########################################################################################

package pkg_sfrs_definition;

   //==========================
   // Chip SFRs
   //==========================
   typedef struct packed {
      logic [31: 8] unimplemented_31_8;
      logic [    7] sw_rst;
      logic [    6] unimplemented_6;
      logic [    5] lw_pwr;
      logic [ 4: 0] unimplemented_4_0;
   } chip_ctrl_t;


   //==========================
   // Timer SFRs types
   //==========================
   typedef struct packed {
      logic [31:16] unimplemented_31_16;
      logic [   15] ovf_f;
      logic [   14] match1_f;
      logic [   13] match0_f;
      logic [   12] unimplemented_12;
      logic [   11] usesclk;
      logic [   10] unimplemented_10;
      logic [ 9: 8] clksrc;
      logic [    7] start;
      logic [    6] stop;
      logic [ 5: 4] unimplemented_5_4;
      logic [    3] rd;
      logic [    2] ld;
      logic [    1] rst;
      logic [    0] on;
   } tmr_ctrl_t;

   typedef struct packed {
      logic [31: 0] tmr_val;
   } tmr_val_t;

   typedef struct packed {
      logic [31: 0] tmr_mch_val0;
   } tmr_match_val0_t;

   typedef struct packed {
      logic [31: 0] tmr_mch_val1;
   } tmr_match_val1_t;
   


endpackage : pkg_sfrs_definition