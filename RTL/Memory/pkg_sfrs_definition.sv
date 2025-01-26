//######################################## Header ########################################
//# Author: Vlad Rosu                                                                    #
//# Description: This package contains UDTs used to describe the SFR signals             #
//########################################################################################

package pkg_sfrs_definition;

   //==========================
   // Chip SFRs
   //==========================
   typedef struct packed {
      logic [23: 0] unimplemented_31_8;   //bits [31: 8]
      logic         sw_rst;               //bits [    7]
      logic         unimplemented_6;      //bits [    6]
      logic         lw_pwr;               //bits [    5]
      logic [ 4: 0] unimplemented_4_0;    //bits [ 4: 0]
   } chip_ctrl_t;


   //==========================
   // Timer SFRs types
   //==========================
   typedef struct packed {
      logic [ 7: 0] unimplemented_31_24;  //bits [31:24]
      logic         ovf_en;               //bits [   23]
      logic         match1_en;            //bits [   22]
      logic         match0_en;            //bits [   21]
      logic [ 4: 0] unimplemented_20_16;  //bits [20:16]
      logic         ovf_f;                //bits [   15]
      logic         match1_f;             //bits [   14]
      logic         match0_f;             //bits [   13]
      logic [ 1: 0] unimplemented_12_11;  //bits [12:11]
      logic [ 2: 0] clksrc;               //bits [10: 8]
      logic         start;                //bits [    7]
      logic         stop;                 //bits [    6]
      logic [ 1: 0] unimplemented_5_4;    //bits [ 5: 4]
      logic         rd;                   //bits [    3]
      logic         ld;                   //bits [    2]
      logic         rst;                  //bits [    1]
      logic         on;                   //bits [    0]
   } tmr_ctrl_t;

   typedef struct packed {
      logic [31: 0] tmr_val;              //bits[31: 0]
   } tmr_val_t;

   typedef struct packed {
      logic [31: 0] tmr_mch_val0;         //bits[31: 0]
   } tmr_match_val0_t;

   typedef struct packed {
      logic [31: 0] tmr_mch_val1;         //bits[31: 0]
   } tmr_match_val1_t;

   //==========================
   // PWM SFRs types
   //==========================
   typedef struct packed {
      logic         ofm_f;                //bits [   31]
      logic         phm_f;                //bits [   30]
      logic         dcm_f;                //bits [   29]
      logic         prm_f;                //bits [   28]
      logic         ofm_en;               //bits [   27]
      logic         phm_en;               //bits [   26]
      logic         dcm_en;               //bits [   25]
      logic         prm_en;               //bits [   24]
      logic [12: 0] unimplemented_23_11;  //bits [23:11]
      logic [ 2: 0] clksrc;               //bits [10: 8]
      logic         pol;                  //bits [    7]
      logic         oen;                  //bits [    6]
      logic         unimplemented_5;      //bits [    5]
      logic         ld_trg;               //bits [    4]
      logic         rd;                   //bits [    3]
      logic         ld;                   //bits [    2]
      logic         rst;                  //bits [    1]
      logic         on;                   //bits [    0]
   } pwm_ctrl_t;

   typedef struct packed {
      logic [15: 0] unimplemented_31_16;  //bits [31:16]
      logic [15: 0] tval;                 //bits [15: 0]
   } pwm_tmr_t;

   typedef struct packed {
      logic [15: 0] dc;                   //bits [31:16]
      logic [15: 0] pr;                   //bits [15: 0]
   } pwm_cfg0_t;

   typedef struct packed {
      logic [15: 0] of;                   //bits [31:16]
      logic [15: 0] ph;                   //bits [15: 0]
   } pwm_cfg1_t;

   //==========================
   // DCO SFRs types
   //==========================
   typedef struct packed {
      logic [20: 0] unimplemented_31_11;  //bits [31:11]
      logic [ 2: 0] clksrc;               //bits [10: 8]
      logic [ 6: 0] unimplemented_7_1;    //bits [ 7: 1]
      logic         on;                   //bits [    0]
   } dco_ctrl_t;

   typedef struct packed {
      logic [11: 0] unimplemented_31_20;  //bits [31:20] 
      logic [19: 0] dcnt;                 //bits [19: 0] 
   } dco_cnt_t;
   


endpackage : pkg_sfrs_definition