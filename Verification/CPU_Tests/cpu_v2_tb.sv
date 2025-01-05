//######################################## Header ########################################
//# Author: Vlad Rosu                                                                    #
//# Description: Tesetbench for cpu_pipeline_v2 aka pipeline CPU                         #
//########################################################################################

module cpu_v2_tb ();

   //Packages and libraries
   import pkg_verification_utils::*;
   
   //Instantiate the DUT
   cpu_pipeline_v2 #(
      .ADDR_WIDTH(32),
      .DATA_WIDTH(32),
      .REG_FILE_ADDR_WIDTH( 5)
   ) dut(
      //    Input ports definition
      .sys_clk       ( tb_clk          ),
      .sys_rst_n     ( tb_rst_n        ),
      .pfm_rd_instr  ( tb_pfm_rd_instr ),
      .dfm_rd_data   ( tb_dfm_rd_data  ),
   //    Output ports definition
      .pfm_req_addr  ( tb_pfm_req_addr ),
      .dfm_req_addr  ( tb_dfm_req_addr ),
      .dfm_wr_en     ( tb_dfm_wr_en    ),
      .dfm_wr_data   ( tb_dfm_wr_data  )
   );

   //DUT inputs
   bit            tb_clk;
   bit            tb_rst_n;
   bit   [31:0]   tb_pfm_rd_instr;
   bit   [31:0]   tb_dfm_rd_data;
   
   //DUT outputs (used logic for outputs because logic is 4-state type)
   logic [31:0]   tb_pfm_req_addr;
   logic [31:0]   tb_dfm_req_addr;
   logic          tb_dfm_wr_en;
   logic [31:0]   tb_dfm_wr_data;

   //TB utilities
   int unsigned   errors = 0;
   int unsigned   test_count = 0;
   logic [31:0]   tb_pfm[0:1024]; //Arbitrary lenght for the pfm memory 
   logic [31:0]   tb_dfm[0:1024]; //Arbitrary lenght for the dfm memory 

   //For debug waveform




   //Clock Generator Thread
   initial begin
      tb_clk <= 0;
      forever #5 tb_clk = !tb_clk;
   end

   //Load tb_mem with the binary program
   initial begin
      $readmemb("machine_code_pfm.bin", tb_pfm);
      $readmemb("machine_code_dfm.bin", tb_dfm);
   end

   //PFM Memory model
   initial begin
      forever begin
         @(posedge tb_clk)
         #2; //add a small delay to avoid race conditions
         tb_pfm_rd_instr = tb_pfm[tb_pfm_req_addr[31:2]];  //Read PFM
      end
   end

   //DFM Memory model
   initial begin
      forever begin
         @(posedge tb_clk)
         #2; //add a small delay to avoid race conditions
         tb_dfm_rd_data = tb_dfm[tb_dfm_req_addr[31:2]]; //Read DFM
         if(tb_dfm_wr_en) tb_dfm[tb_dfm_req_addr[31:2]] = tb_dfm_wr_data; //Write DFM
      end
   end

   //Run the tests
   initial begin
      tb_rst_n = 1'b0;
      @(negedge tb_clk);
      tb_rst_n = 1'b1;

      #1000;

      $display("Stopping simulation.");
      $finish;
   end


endmodule : cpu_v2_tb