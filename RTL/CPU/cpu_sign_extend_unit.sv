module cpu_sign_extend_unit #(
   parameter DATA_WIDTH = 32
)(   
   //    Input ports definition
   input  [          31:7] imd, //TODO Can the dimension of this be automated (currently it is fixed for this arthitecture only)
   input  [           1:0] imd_src,
   //    Output ports definition
   output [DATA_WIDTH-1:0] imd_ext
);

   logic [DATA_WIDTH-1:0] mux_out;

   // Extend the sign bit to obtain a DATA_WIDTH-1 long operand
   always_comb begin
      mux_out = '0;
      case (imd_src)
         2'b00: mux_out = { {(DATA_WIDTH-12){imd[31]}}, imd[31:20]                                           }; //For I-Type Instructions - 12bit signed immediate
         2'b01: mux_out = { {(DATA_WIDTH-12){imd[31]}}, imd[31:25], imd[11: 7]                               }; //For S-Type Instructions - 12bit signed immediate
         2'b10: mux_out = { {(DATA_WIDTH-13){imd[31]}}, imd[   31], imd[    7], imd[30:25], imd[11: 8], 1'b0 }; //For B-Type Instructions - 13bit signed immediate
         2'b11: mux_out = { {(DATA_WIDTH-21){imd[31]}}, imd[   31], imd[19:12], imd[   20], imd[30:21], 1'b0 }; //For J-Type Instructions - 21bit signed immediate
      endcase
   end

   assign imd_ext = mux_out;

   `ifdef DESIGNER_ASSERTIONS
      //TODO add assertions
   `endif

endmodule : cpu_sign_extend_unit