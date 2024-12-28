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
   // Timer 0 SFRs
   //==========================
   typedef struct packed {
      logic [31:16] unimplemented_31_16;
      logic [   15] ovf_f;
      logic [   14] match_f;
      logic [13:12] unimplemented_13_12;
      logic [   11] usesclk;
      logic [   10] unimplemented_10;
      logic [ 9: 8] clksrc;
      logic [    7] oen;
      logic [    6] oinv;
      logic [ 5: 3] unimplemented_5_3;
      logic [    2] ld;
      logic [    1] rst;
      logic [    0] on;
   } tmr0_ctrl_t;

   typedef struct packed {
      logic [31: 0] tval;
   } tmr0_val_t;

   typedef struct packed {
      logic [31: 0] tmch;
   } tmr0_match_val_t;
   


endpackage : pkg_sfrs_definition