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
      logic [31:24] unimplemented_31_24;
      logic [   23] ovf_en;
      logic [   22] match0_en;
      logic [   21] match1_en;
      logic [20:16] unimplemented_20_16;
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

   //==========================
   // PWM SFRs types
   //==========================
   typedef struct packed {
      logic [   31] ofm_f;
      logic [   30] phm_f;
      logic [   29] dcm_f;
      logic [   28] prm_f;
      logic [   27] ofm_en;
      logic [   26] phm_en;
      logic [   25] dcm_en;
      logic [   24] prm_en;
      logic [23:12] unimplemented_23_12;
      logic [   11] usesclk;
      logic [   10] unimplemented_10;
      logic [ 9: 8] clksrc;
      logic [    7] pol;
      logic [    6] oen;
      logic [    5] unimplemented_5;
      logic [    4] ld_trg;
      logic [    3] rd;
      logic [    2] ld;
      logic [    1] rst;
      logic [    0] on;
   } pwm_ctrl_t;

   typedef struct packed {
      logic [31:16] unimplemented_31_16;
      logic [15: 0] tval;
   } pwm_tmr_t;

   typedef struct packed {
      logic [31:16] dc;
      logic [15: 0] pr;
   } pwm_cfg0_t;

   typedef struct packed {
      logic [31:16] of;
      logic [15: 0] ph;
   } pwm_cfg1_t;

   //==========================
   // DCO SFRs types
   //==========================
   typedef struct packed {
      logic [31:12] unimplemented_31_12;
      logic [   11] usesclk;
      logic [   10] unimplemented_10;
      logic [ 9: 8] clksrc;
      logic [ 7: 1] unimplemented_7_1;
      logic [    0] on;
   } dco_ctrl_t;

   typedef struct packed {
      logic [31:20] unimplemented_31_20;
      logic [19: 0] dcnt;
   } dco_cnt_t;
   


endpackage : pkg_sfrs_definition