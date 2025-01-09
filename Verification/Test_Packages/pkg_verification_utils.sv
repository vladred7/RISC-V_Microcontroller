//######################################## Header ########################################
//# Author: Vlad Rosu                                                                    #
//# Description: This package contains UDTs, Classes, Functions, Taks used in the        #
//#              verification process                                                    #
//########################################################################################

package pkg_verification_utils;

   //+--------------------------------------------------------------+//
   //|                    User Defined Data Types                   |//
   //+--------------------------------------------------------------+//

   typedef enum bit [2:0] {
      ADD   = 3'b000,
      SUB   = 3'b001,
      AND   = 3'b010,
      OR    = 3'b011,
      SLT   = 3'b101
   } alu_opcode_t;

   typedef enum bit [4:0] {
      ZERO  = 'd0,   // Constant Value of 0
      RA    = 'd1,   // Return Address
      SP    = 'd2,   // Stack Pointer
      GP    = 'd3,   // Global Pointer
      TP    = 'd4,   // Thread Pointer
      T0    = 'd5,   // Temporary Register 0
      T1    = 'd6,   // Temporary Register 1
      T2    = 'd7,   // Temporary Register 2
      S0    = 'd8,   // Saved Register 0/Frame Pointer = S0/FP
      S1    = 'd9,   // Saved Register 1
      A0    = 'd10,  // Function argument 0 / Return value 0
      A1    = 'd11,  // Function argument 1 / Return value 1
      A2    = 'd12,  // Function argument 2
      A3    = 'd13,  // Function argument 3
      A4    = 'd14,  // Function argument 4
      A5    = 'd15,  // Function argument 5
      A6    = 'd16,  // Function argument 6
      A7    = 'd17,  // Function argument 7
      S2    = 'd18,  // Saved Register 2
      S3    = 'd19,  // Saved Register 3
      S4    = 'd20,  // Saved Register 4
      S5    = 'd21,  // Saved Register 5
      S6    = 'd22,  // Saved Register 6
      S7    = 'd23,  // Saved Register 7
      S8    = 'd24,  // Saved Register 8
      S9    = 'd25,  // Saved Register 9
      S10   = 'd26,  // Saved Register 10
      S11   = 'd27,  // Saved Register 11
      T3    = 'd28,  // Temporary Register 3
      T4    = 'd29,  // Temporary Register 4
      T5    = 'd30,  // Temporary Register 5
      T6    = 'd31   // Temporary Register 6
   } cpu_regset_t;

   typedef enum bit [2:0] {
      FETCH ,
      DECODE,
      EXECUTE,
      MEM_ACC,
      RFL_WRB
   } cpu_state_t;

   typedef enum bit [6:0] { //These instruction opcodes represents the RV32I set
      LOAD     = 7'b0000011,
      I_TYPE   = 7'b0010011,
      AUI_PC   = 7'b0010111,
      S_TYPE   = 7'b0100011,
      R_TYPE   = 7'b0110011,
      LUI      = 7'b0110111,
      B_TYPE   = 7'b1100011,
      JALR     = 7'b1100111,
      J_TYPE   = 7'b1101111
   } cpu_opcode_t;

   //+--------------------------------------------------------------+//
   //|                            Classes                           |//
   //+--------------------------------------------------------------+//

   //Declare an abstract class as a template for all register tests
   virtual class register_standard_tests_c;
      //Reset Test
      pure virtual task reset_test();
      
      //Bit Bash Test
      pure virtual task bit_bash_test();

      //Write-Read All Test
      pure virtual task write_read_all_test();

      //Write-Read Test (patterns)
      pure virtual task write_read_test();

      //Hardware Update fields Test
      pure virtual task hw_up_bit_test();

      //Hardware/Software Update Priority Test
      pure virtual task hwsw_up_prio_test();

   endclass : register_standard_tests_c

endpackage : pkg_verification_utils