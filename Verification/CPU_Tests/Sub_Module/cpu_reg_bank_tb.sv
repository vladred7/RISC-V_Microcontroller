//######################################## Header ########################################
//# Author: Vlad Rosu                                                                    #
//# Description: Testbench for register file containing 32 registers specialized on      #
//#              32 bit data                                                             #
//########################################################################################

module cpu_reg_bank_tb ();

   //Packages and libraries
   import pkg_verification_utils::*;
   
   //Instantiate the DUT
   cpu_reg_bank #(
         .ADDR_WIDTH(5),
         .DATA_WIDTH(32)
      ) dut(
         //    Input ports
         .clk   ( tb_clk    ),
         .rst_n ( tb_rst_n  ),
         .a1    ( tb_addr1  ),
         .a2    ( tb_addr2  ),
         .a3    ( tb_addr3  ),
         .wen3  ( tb_wen3   ),
         .wd3   ( tb_wdata3 ),
         //    Output ports
         .rd1   ( dut_rd1   ),
         .rd2   ( dut_rd2   )
      );
   
   //DUT inputs
   bit            tb_clk;
   bit            tb_rst_n;
   bit   [ 4:0]   tb_addr1;
   bit   [ 4:0]   tb_addr2;
   bit   [ 4:0]   tb_addr3;
   bit            tb_wen3;
   bit   [31:0]   tb_wdata3;
   
   //DUT outputs (used logic for outputs because logic is 4-state type)
   logic [31:0]   dut_rd1;
   logic [31:0]   dut_rd2;

   //TB utilities
   int unsigned   errors = 0;
   int unsigned   test_count = 0;

   //For debug waveform
   logic [31:0]   wave_exp_rd1;
   logic [31:0]   wave_exp_rd2;

   class model_reg_file_c;
      //Class Properties
      local bit [31:0] reg_map[0:31]; // array of 32 registers

      //Class Methods
      function new();
         foreach (this.reg_map[i]) begin
            this.reg_map[i] = '0;
         end
      endfunction : new

      function void write_register_file(bit [4:0] addr3, bit [31:0] data3);
         if(addr3 !== 0) //register location 0 is hardwired to 0's
            reg_map[addr3] = data3;
      endfunction : write_register_file

      //This function return 64 bits because return both register values with rd1 as the LSW
      function logic [63:0] read_register_file(bit [4:0] addr1, bit [4:0] addr2);
         wave_exp_rd1 = reg_map[addr1]; // update this variable to display it on the waveform
         wave_exp_rd2 = reg_map[addr2]; // update this variable to display it on the waveform
         return {reg_map[addr2],reg_map[addr1]};
      endfunction : read_register_file

      function void reset_register_file();
         foreach (this.reg_map[i]) begin
            this.reg_map[i] = '0;
         end
      endfunction : reset_register_file
      
   endclass : model_reg_file_c

   class reg_file_tests_c extends register_standard_tests_c;
      
      function void check_outputs(logic [63:0] expected, logic [63:0] dut_out);
         if(dut_out !== expected) begin
            errors++;
            $display("ERROR!!! -> Time %0t: expected=%0h, dut_out=%0h",$time(), expected, dut_out);
         end

         test_count++; //increment test_count for each test
      endfunction : check_outputs

      function void report_passrate();
         $display("Pass Rate: %3.2f%%",((test_count-errors)/real'(test_count))*100);
         //After each report clear the number of tests and errors
         test_count = 0;
         errors = 0;
      endfunction : report_passrate

      task read_seq(bit [4:0] addr1, bit [4:0] addr2);
         //Put the addresses on the DUT input
         cb.tb_addr1 <= addr1;
         cb.tb_addr2 <= addr2;
         //Wait one clock
         @cb;
      endtask : read_seq

      task write_seq(bit [4:0] addr3, bit [31:0] data3);
         //Put the address/data on the DUT input and set write_enable
         cb.tb_wdata3 <= data3;
         cb.tb_addr3  <= addr3;
         cb.tb_wen3   <= 1'b1;
         //Wait one clock
         @cb;
         //Deassert wen
         cb.tb_wen3   <= 1'b0;
      endtask : write_seq

      task reset_seq(model_reg_file_c reg_file);
         fork
            //Thread 1 : Reset the DUT
            begin
               tb_rst_n = 0;
               repeat(2) @(posedge tb_clk);
               tb_rst_n = 1;
            end
            //Thread 2 : Reset the Model
            begin
               reg_file.reset_register_file();
            end
         join
         //Synchronize with the clocking block
         @cb;
      endtask : reset_seq

      task reset_test();
         model_reg_file_c reg_file = new();
         
         //Synchronize with the posedge of tb_clk
         @(posedge tb_clk);
         //Reset sequence
         reset_seq(reg_file);

         for (int reg_idx = 0; reg_idx < 32; reg_idx = reg_idx + 2) begin
            logic [31:0] exp_rd1;
            logic [31:0] exp_rd2;

            fork
               begin //DUT Read
                  read_seq(reg_idx,reg_idx+1);
               end
               begin //Model Read
                  {exp_rd2, exp_rd1} = reg_file.read_register_file(reg_idx,reg_idx+1);
               end
            join

            check_outputs({dut_rd2,dut_rd1}, {exp_rd2, exp_rd1});
         end

         //Report results
         report_passrate();
      endtask : reset_test


      task bit_bash_test();
         model_reg_file_c reg_file = new();

         //Reset sequence
         reset_seq(reg_file);

         for (int reg_idx = 0; reg_idx < 32; reg_idx++) begin
            logic [31:0] exp_rd1;
            logic [31:0] exp_rd2;

            for (int reg_bit_idx = 0; reg_bit_idx < 32; reg_bit_idx++) begin
               logic [31:0] data = '0;

               //Set the data as power of 2's to bash every bit in the register
               data = 2**reg_bit_idx;

               //Write the data
               fork
                  begin //DUT Write
                     write_seq(reg_idx, data);
                  end
                  begin //Model Write
                     reg_file.write_register_file(reg_idx, data);
                  end
               join

               //Read the data back
               fork
                  begin //DUT Read
                     read_seq(reg_idx,0);
                  end
                  begin //Model Read
                     {exp_rd2, exp_rd1} = reg_file.read_register_file(reg_idx,0);
                  end
               join
               
               check_outputs(dut_rd1, exp_rd1);
            end
         end

         //Report results
         report_passrate();
      endtask : bit_bash_test


      task write_read_all_test();
         model_reg_file_c reg_file = new();

         for (int reg_idx_write = 0; reg_idx_write < 32; reg_idx_write++) begin
            logic [31:0] exp_rd1;
            logic [31:0] exp_rd2;
            logic [31:0] data;

            //Reset sequence
            reset_seq(reg_file);

            data = $urandom();

            //Write the data
            fork
               begin //DUT Write
                  write_seq(reg_idx_write, data);
               end
               begin //Model Write
                  reg_file.write_register_file(reg_idx_write, data);
               end
            join

            for (int reg_idx_read = 0; reg_idx_read < 32; reg_idx_read = reg_idx_read + 2) begin
               //Read all the registers
               fork
                  begin //DUT Read
                     read_seq(reg_idx_read, reg_idx_read+1);
                  end
                  begin //Model Read
                     {exp_rd2, exp_rd1} = reg_file.read_register_file(reg_idx_read, reg_idx_read+1);
                  end
               join
               
               check_outputs({dut_rd2,dut_rd1}, {exp_rd2, exp_rd1});
            end
         end

         //Report results
         report_passrate();
      endtask : write_read_all_test


      task write_read_test();
         model_reg_file_c reg_file = new();

         //Reset sequence
         reset_seq(reg_file);

         for (int reg_idx = 0; reg_idx < 32; reg_idx++) begin
            logic [31:0] exp_rd1;
            logic [31:0] exp_rd2;

            //Write Patterns
            //32'h0000_0000
            fork //Write
               begin //DUT Write
                  write_seq(reg_idx, 32'h0000_0000); //write one location with its index
               end
               begin //Model Write
                  reg_file.write_register_file(reg_idx, 32'h0000_0000);
               end
            join

            fork //Read
               begin //DUT Read
                  read_seq(reg_idx, 0);
               end
               begin //Model Read
                  {exp_rd2, exp_rd1} = reg_file.read_register_file(reg_idx, 0);
               end
            join

            check_outputs(dut_rd1, exp_rd1);

            //32'h5555_5555
            fork //Write
               begin //DUT Write
                  write_seq(reg_idx, 32'h5555_5555); //write one location with its index
               end
               begin //Model Write
                  reg_file.write_register_file(reg_idx, 32'h5555_5555);
               end
            join

            fork //Read
               begin //DUT Read
                  read_seq(reg_idx, 0);
               end
               begin //Model Read
                  {exp_rd2, exp_rd1} = reg_file.read_register_file(reg_idx, 0);
               end
            join

            check_outputs(dut_rd1, exp_rd1);

            //32'hAAAA_AAAA
            fork //Write
               begin //DUT Write
                  write_seq(reg_idx, 32'hAAAA_AAAA); //write one location with its index
               end
               begin //Model Write
                  reg_file.write_register_file(reg_idx, 32'hAAAA_AAAA);
               end
            join

            fork //Read
               begin //DUT Read
                  read_seq(reg_idx, 0);
               end
               begin //Model Read
                  {exp_rd2, exp_rd1} = reg_file.read_register_file(reg_idx, 0);
               end
            join

            check_outputs(dut_rd1, exp_rd1);

            //32'hFFFF_FFFF
            fork //Write
               begin //DUT Write
                  write_seq(reg_idx, 32'hFFFF_FFFF); //write one location with its index
               end
               begin //Model Write
                  reg_file.write_register_file(reg_idx, 32'hFFFF_FFFF);
               end
            join

            fork //Read
               begin //DUT Read
                  read_seq(reg_idx, 0);
               end
               begin //Model Read
                  {exp_rd2, exp_rd1} = reg_file.read_register_file(reg_idx, 0);
               end
            join

            check_outputs(dut_rd1, exp_rd1);

            //Write Random Values
            for (int i = 0; i < 100; i++) begin
               logic [31:0] data;

               data = $urandom();

               fork //Write
                  begin //DUT Write
                     write_seq(reg_idx, data); //write one location with its index
                  end
                  begin //Model Write
                     reg_file.write_register_file(reg_idx, data);
                  end
               join

               fork //Read
                  begin //DUT Read
                     read_seq(reg_idx, 0);
                  end
                  begin //Model Read
                     {exp_rd2, exp_rd1} = reg_file.read_register_file(reg_idx, 0);
                  end
               join

               check_outputs(dut_rd1, exp_rd1);
            end
            
         end

         //Report results
         report_passrate();
      endtask : write_read_test

      task hw_up_bit_test();
         $display("This test is not required!");
      endtask : hw_up_bit_test

      task hwsw_up_prio_test();
         $display("This test is not required!");
      endtask : hwsw_up_prio_test

   endclass : reg_file_tests_c 

   //Define a clocking block for the input signals
   // Clocking block
   clocking cb @(posedge tb_clk);
      //Sample
      input dut_rd1;
      input dut_rd2;
      //Drive
      output tb_addr1;
      output tb_addr2;
      output tb_addr3;
      output tb_wen3;
      output tb_wdata3;
   endclocking

   //Clock Generator Thread
   initial begin
      tb_clk <= 0;
      forever #5 tb_clk = !tb_clk;
   end

   //Run the tests
   initial begin
      //Create the test_sequence object
      reg_file_tests_c test_sequence = new();

      //Synchronize with the posedge of tb_clk
      @(posedge tb_clk);

      $display("//+--------------------------------------------------------------+//");
      $display("//|                       Reset Test Start                       |//");
      $display("//+--------------------------------------------------------------+//");
      test_sequence.reset_test();

      $display("//+--------------------------------------------------------------+//");
      $display("//|                     Bit Bash Test Start                      |//");
      $display("//+--------------------------------------------------------------+//");
      test_sequence.bit_bash_test();

      $display("//+--------------------------------------------------------------+//");
      $display("//|                Write one Read all Test Start                 |//");
      $display("//+--------------------------------------------------------------+//");
      test_sequence.write_read_all_test();

      $display("//+--------------------------------------------------------------+//");
      $display("//|                    Write-Read Test Start                     |//");
      $display("//+--------------------------------------------------------------+//");
      test_sequence.write_read_test();

      $display("//+--------------------------------------------------------------+//");
      $display("//|              Hardware Update fields Test Start               |//");
      $display("//+--------------------------------------------------------------+//");
      test_sequence.hw_up_bit_test();

      $display("//+--------------------------------------------------------------+//");
      $display("//|        Hardware/Software Update Priority Test Start          |//");
      $display("//+--------------------------------------------------------------+//");
      test_sequence.hwsw_up_prio_test();

      $display("Stopping simulation.");
      $finish;
   end

endmodule : cpu_reg_bank_tb