//######################################## Header ########################################
//# Author: Vlad Rosu                                                                    #
//# Description: Testbench for sign extent unit specialized on 32 bit data               #
//########################################################################################

module cpu_sign_extend_unit_tb ();

   cpu_sign_extend_unit #(
      .DATA_WIDTH(32)
   ) dut(
      //    Input ports
      .imd           ( tb_imd_data      ),
      .imd_src       ( tb_imd_src       ),
      //    Output ports
      .imd_ext       ( dut_imd_ext_data )
   );

   //DUT Inputs
   logic [24:0]   tb_imd_data;
   logic [ 1:0]   tb_imd_src;

   //DUT Outputs
   logic [31:0]   dut_imd_ext_data;

   //TB utilities
   int unsigned   errors = 0;
   int unsigned   test_count = 0;
   logic [31:0]   exp_imd_ext_data;

   function void randomize_test_inputs();
      tb_imd_data = $urandom();
      tb_imd_src  = $urandom();
   endfunction : randomize_test_inputs

   function logic [31:0] sign_ext_unit_model(logic [24:0] imd_data, logic [1:0] imd_src);
      logic [31:0] result;

      case (imd_src)
         2'b00: result = { {21{imd_data[24]}}, imd_data[23:13] };
         2'b01: result = { {21{imd_data[24]}}, imd_data[23:18], imd_data[4:0] };
         2'b10: result = { {20{imd_data[24]}}, imd_data[0], imd_data[23:18], imd_data[4:1], 1'b0 };
         2'b11: result = { {12{imd_data[24]}}, imd_data[12:5], imd_data[13], imd_data[23:14], 1'b0 };
      endcase

      return result;
   endfunction : sign_ext_unit_model

   initial begin
      // X Propagation
      #10;

      test_count = 1000;

      for (int i = 0; i < test_count; i++) begin
         randomize_test_inputs();
         exp_imd_ext_data = sign_ext_unit_model(tb_imd_data,tb_imd_src);
         #1;
         if(dut_imd_ext_data !== exp_imd_ext_data)
            errors++;
         #9;
      end

      #1;

      $display("Pass Rate: %3.3f%%",((test_count-errors)/test_count)*100);
      $display("Stopping simulation.");
      $finish;
   end

endmodule : cpu_sign_extend_unit_tb