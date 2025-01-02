//######################################## Header ########################################
//# Author: Vlad Rosu                                                                    #
//# Description: Tesetbench for cpu_multicycle_v1 aka multicycle CPU                     #
//########################################################################################

module cpu_v1_tb ();

   //Packages and libraries
   import pkg_verification_utils::*;
   
   //Instantiate the DUT
   cpu_multicycle_v1 #(
      .ADDR_WIDTH(32),
      .DATA_WIDTH(32),
      .REG_FILE_ADDR_WIDTH( 5)
   ) dut(
      //    Input ports
      .sys_clk        ( tb_clk          ),
      .sys_rst_n      ( tb_rst_n        ),
      .mem_data_out   ( tb_mem_data_out ),
      //    Output ports
      .mem_wr_en      ( dut_mem_wr_en   ),
      .mem_addr       ( dut_mem_addr    ),
      .mem_data_in    ( dut_mem_data_in )
   );

   //DUT inputs
   bit            tb_clk;
   bit            tb_rst_n;
   bit   [31:0]   tb_mem_data_out;
   
   //DUT outputs (used logic for outputs because logic is 4-state type)
   logic          dut_mem_wr_en;
   logic [31:0]   dut_mem_addr;
   logic [31:0]   dut_mem_data_in;

   //TB utilities
   int unsigned   errors = 0;
   int unsigned   test_count = 0;
   logic [31:0]   tb_mem[0:1024];

   //For debug waveform




   //Clock Generator Thread
   initial begin
      tb_clk <= 0;
      forever #5 tb_clk = !tb_clk;
   end

   //Load tb_mem with the binary program
   initial begin
      $readmemb("machine_code.bin", tb_mem);
   end

   initial begin
      forever begin
         tb_mem_data_out = tb_mem[dut_mem_addr[31:2]];
         if(dut_mem_wr_en) tb_mem[dut_mem_addr[31:2]] = dut_mem_data_in;
         @(negedge tb_clk); 
      end
   end

   //Run the tests
   initial begin
      tb_rst_n = 1'b0;
      @(negedge tb_clk);
      tb_rst_n = 1'b1;

      #6000;

      $display("Stopping simulation.");
      $finish;
   end


endmodule : cpu_v1_tb