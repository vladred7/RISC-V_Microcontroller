//######################################## Header ########################################
//# Author: Vlad Rosu                                                                    #
//# Description: This package contains UDTs used CPU design                              #
//########################################################################################

package pkg_cpu_typedefs;

   typedef enum bit [2:0] {
      ADD   = 3'b000,
      SUB   = 3'b001,
      AND   = 3'b010,
      OR    = 3'b011,
      SLT   = 3'b101
   } alu_opcode_t;
   
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

   typedef struct packed {
      logic [6:0]  funct7;  //bits [31:25] of the instruction
      cpu_regset_t rs2;     //bits [24:20] of the instruction
      cpu_regset_t rs1;     //bits [19:15] of the instruction
      logic [2:0]  funct3;  //bits [14:12] of the instruction
      cpu_regset_t rd;      //bits [11: 7] of the instruction
      cpu_opcode_t opc;     //bits [ 6: 0] of the instruction
   } instr_t;

   typedef struct packed {
      logic [24:0] imd_data;  //bits [31: 7] of the instruction
      logic [ 6:0] not_used;  //bits [ 6: 0] of the instruction
   } immediate_t;

   typedef union packed {
      instr_t      instruction;
      immediate_t  data;
   } instr_reg_t;

   typedef enum bit [2:0] { //TODO Gray code the cpu_states
      FETCH       = 'd0, //Fetch stage - access the memory based on PC and calculate next_PC in ALU
      DECODE      = 'd1, //Decode stage - decode the current instruction and calculate the branch address in ALU
      EXECUTE     = 'd2, //Execute stage - execute the specific instruction
      MEM_ACC     = 'd3, //Memory stage - read/write to the memory
      RFL_WRB     = 'd4  //Write Back stage - write the register file if needed
   } cpu_state_t;

endpackage : pkg_cpu_typedefs