//######################################## Header ########################################
//# Author: Vlad Rosu                                                                    #
//# Description: Parameterizable sign extend unit specific for a RISCV instruction set   #
//########################################################################################

module cpu_sign_extend_unit #(
   parameter DATA_WIDTH = 32
)(   
   //    Input ports definition
   input  [          31:7] imd, //TODO Can the dimension of this be automated (currently it is fixed for this arthitecture only)
   input  [           2:0] imd_src,
   //    Output ports definition
   output [DATA_WIDTH-1:0] imd_ext
);

   logic [DATA_WIDTH-1:0] mux_out;

   // Extend the sign bit to obtain a DATA_WIDTH-1 long operand
   always_comb begin
      mux_out = '0;
      case (imd_src)
         3'b000: mux_out = { {(DATA_WIDTH-12){imd[31]}}, imd[31:20]                                           }; //For I-Type Instructions - 12bit signed immediate
         3'b001: mux_out = { {(DATA_WIDTH-12){imd[31]}}, imd[31:25], imd[11: 7]                               }; //For S-Type Instructions - 12bit signed immediate
         3'b010: mux_out = { {(DATA_WIDTH-13){imd[31]}}, imd[   31], imd[    7], imd[30:25], imd[11: 8], 1'b0 }; //For B-Type Instructions - 13bit signed immediate
         3'b011: mux_out = { {(DATA_WIDTH-21){imd[31]}}, imd[   31], imd[19:12], imd[   20], imd[30:21], 1'b0 }; //For J-Type Instructions - 21bit signed immediate
         3'b100: mux_out = { imd[31:12], {(DATA_WIDTH-20){1'b0}}                                              }; //For U-Type Instructions - upper 20bits of the immediate
      endcase
   end

   assign imd_ext = mux_out;

   `ifdef DESIGNER_ASSERTIONS
      //TODO add assertions
   `endif

endmodule : cpu_sign_extend_unit