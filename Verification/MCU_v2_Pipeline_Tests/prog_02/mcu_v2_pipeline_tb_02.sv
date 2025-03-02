//######################################## Header ########################################
//# Author: Vlad Rosu                                                                    #
//# Description: Tesetbench for mcu_v2_pipeline                                          #
//########################################################################################

module mcu_v2_pipeline_tb_02 ();

   //Packages and libraries
   import pkg_verification_utils::*;
   
   //Instantiate the DUT
   mcu_v2_pipeline #(
   .ADDR_BUS_WIDTH(32),
   .DATA_BUS_WIDTH(32),
   .CPU_REG_FILE_ADDR_WIDTH(5)
   ) dut(
      //    Input ports definition
      .sys_clk       ( tb_clk             ),
      .sys_rst_n     ( tb_rst_n           ),
      //    Output ports definition
      .pfm_rd_instr  ( dut_pfm_rd_instr   ),
      .dfm_rd_data   ( dut_dfm_rd_data    ),
      .pfm_req_addr  ( dut_pfm_req_addr   ),
      .cpu_req_addr  ( dut_cpu_req_addr   ),
      .cpu_wr_en     ( dut_cpu_wr_en      ),
      .cpu_wr_data   ( dut_cpu_wr_data    ),
      .sys_rd_bus    ( dut_sys_rd_bus     )
   );

   //DUT inputs
   bit            tb_clk;
   bit            tb_rst_n;

   //TB utilities

   //Clock Generator Thread
   initial begin
      tb_clk <= 0;
      forever #500ns tb_clk = !tb_clk;
   end

   //Load tb_mem with the binary program
   initial begin
      $readmemb("pfm.bin", dut.pfm.mem_map);
      $readmemb("dfm.bin", dut.dfm.mem_map);
   end

   // //PFM Memory model
   // initial begin
   //    forever begin
   //       @(posedge tb_clk)
   //       #2; //add a small delay to avoid race conditions
   //       tb_pfm_rd_instr = tb_pfm[tb_pfm_req_addr[31:2]];  //Read PFM
   //    end
   // end

   // //DFM Memory model
   // initial begin
   //    forever begin
   //       @(posedge tb_clk)
   //       #2; //add a small delay to avoid race conditions
   //       if(tb_dfm_req_addr[31:28] == 4'b0001) begin
   //          tb_dfm_rd_data = tb_dfm[tb_dfm_req_addr[27:2]]; //Read DFM
   //          if(tb_dfm_wr_en) tb_dfm[tb_dfm_req_addr[27:2]] = tb_dfm_wr_data; //Write DFM
   //       end
   //    end
   // end

   //Run the tests
   initial begin
      logic [31:0] dfm_gold[0:1023];
      int unsigned            errors = 0;
      int unsigned            test_count = 0;
   
      tb_rst_n = 1'b0;
      @(negedge tb_clk);
      tb_rst_n = 1'b1;

      #2000us;

      $display("Stopping simulation.");
      begin
         //Read the gold DFM
         $readmemb("dfm_gold.bin", dfm_gold);
         foreach (dfm_gold[i]) begin
            test_count++;
            if(dfm_gold[i] !== dut.dfm.mem_map[i]) begin
               errors++;
            end
         end
         $display("Pass Rate: %3.2f%%",((test_count-errors)/real'(test_count))*100);
         
         $display("Dumping Memory content in dfm_sim_result.bin");
         $writememb("dfm_sim_result.bin", dut.dfm.mem_map);
      end
      
      $finish;
   end
   
endmodule : mcu_v2_pipeline_tb_02