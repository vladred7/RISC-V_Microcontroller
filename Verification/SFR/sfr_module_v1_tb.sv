//######################################## Header ########################################
//# Author: Vlad Rosu                                                                    #
//# Description: Testbench for SFR module specialized on 32 bit data                     #
//########################################################################################

module sfr_module_v1_tb#(
   parameter ADDR_WIDTH  = 32,
   parameter DATA_WIDTH  = 32,
   parameter ADDRESS     = 10,
   parameter IBITS_MASK  = 32'h1800_EFFF,
   parameter RBITS_MASK  = 32'h1000_01FF,
   parameter SW_UPD_MASK = 32'h30FF_FFFF,
   parameter HW_UPD_MASK = 32'h0C00_0001
) ();

   //Packages and libraries
   import pkg_verification_utils::*;

   //Instantiate the DUT
   sfr_module_v1 #(
      .SFR_ADDR_WIDTH(ADDR_WIDTH),
      .SFR_WIDTH(DATA_WIDTH),
      .SFR_ADDRESS(ADDRESS),
      .IMPLEMENTED_BITS_MASK(IBITS_MASK),
      .READABLE_BITS_MASK(RBITS_MASK),
      .SW_UPDATABLE_BITS_MASK(SW_UPD_MASK),
      .HW_UPDATABLE_BITS_MASK(HW_UPD_MASK)
   ) dut(
      //    Input ports
      .sys_clk          ( tb_clk          ),
      .sys_clk_en       ( tb_clk_en       ),
      .sys_rst_n        ( tb_rst_n        ),
      .sys_addr         ( tb_addr         ),
      .sys_wr_en        ( tb_wen          ),
      .sfr_hw_upate     ( tb_hw_update    ),
      .sfr_hw_value     ( tb_hw_value     ),
      .sfr_sw_value     ( tb_sw_value     ),
      //    Output ports
      .sfr_dout         ( dut_dout        ),
      .sfr_rdonly_dout  ( dut_rdonly_dout )
   );
   
   //DUT inputs
   bit                     tb_clk;
   bit                     tb_clk_en;
   bit                     tb_rst_n;
   bit   [ADDR_WIDTH-1:0]  tb_addr;
   bit                     tb_wen;
   bit   [DATA_WIDTH-1:0]  tb_hw_update;
   bit   [DATA_WIDTH-1:0]  tb_hw_value;
   bit   [DATA_WIDTH-1:0]  tb_sw_value;
   
   //DUT outputs (used logic for outputs because logic is 4-state type)
   logic [DATA_WIDTH-1:0]  dut_dout;
   logic [DATA_WIDTH-1:0]  dut_rdonly_dout;

   //TB utilities
   int unsigned   errors = 0;
   int unsigned   test_count = 0;

   //For debug waveform
   logic [31:0]   wave_exp_dut_out;
   logic [31:0]   wave_exp_dut_ronly_out;

   class model_sfr_c;
      //Class Properties
      local bit [DATA_WIDTH-1:0] sfr_val;
      local bit [ADDR_WIDTH-1:0] addr;
      local bit clk_en;

      //Class Methods
      function new();
            this.sfr_val = '0;
            this.addr = ADDRESS;
            this.clk_en = 1'b1; //by default the clock is enabled
      endfunction : new

      function void write_sfr(
         logic [ADDR_WIDTH-1:0] addr, 
         logic                  wren,
         logic [DATA_WIDTH-1:0] hw_upd,
         logic [DATA_WIDTH-1:0] hw_upd_val,
         logic [DATA_WIDTH-1:0] sw_upd_val
         );

         bit sfr_wren;
         bit [DATA_WIDTH-1:0] hwup;

         sfr_wren = (addr === this.addr) && wren;
         
         if(sfr_wren && this.clk_en) this.sfr_val = sw_upd_val & SW_UPD_MASK & IBITS_MASK;
         
         hwup = hw_upd & HW_UPD_MASK & IBITS_MASK;
         //Overwrite the sfr value with the hardware value if there is any hw update
         for (int i = 0; i < DATA_WIDTH; i++) begin
            if(hwup[i] && this.clk_en) this.sfr_val[i] = hw_upd_val[i];
         end
      endfunction : write_sfr

      function logic [(DATA_WIDTH*2)-1:0] read_sfr(logic [ADDR_WIDTH-1:0] addr);
         if(addr === this.addr) begin
            {wave_exp_dut_out,wave_exp_dut_ronly_out} = {this.sfr_val, (this.sfr_val & RBITS_MASK & IBITS_MASK)};
            return {this.sfr_val, (this.sfr_val & RBITS_MASK & IBITS_MASK)}; //return the sfr value and the readable bits
         end else begin
            return '0;
         end
      endfunction : read_sfr

      function void reset_sfr();
         this.sfr_val = '0;
      endfunction : reset_sfr

      function void set_clk_en(bit value);
         this.clk_en = value;
      endfunction : set_clk_en
      
   endclass : model_sfr_c

   class sfr_tests_c extends register_standard_tests_c;
      
      function void check_outputs(logic [(DATA_WIDTH*2)-1:0] dut_out, logic [(DATA_WIDTH*2)-1:0] expected);
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

      task read_seq(bit [ADDR_WIDTH-1:0] addr);
         //Put the address on the DUT input
         cb.tb_addr <= addr;
         //Wait one clock
         @cb;
      endtask : read_seq

      task write_seq(
         bit [ADDR_WIDTH-1:0] addr,
         bit                  wen,
         bit [DATA_WIDTH-1:0] hw_upd,
         bit [DATA_WIDTH-1:0] hw_data,
         bit [DATA_WIDTH-1:0] sw_data
         );
         
         //Put the address/data on the DUT input and set write_enable for sofware control
         cb.tb_addr        <= addr;
         cb.tb_wen         <= wen;
         cb.tb_sw_value    <= sw_data;
         //Control the hardware updates
         cb.tb_hw_update   <= hw_upd;
         cb.tb_hw_value    <= hw_data;
         
         //Wait one clock
         @cb;
         //Deassert wen/hw_upd if it was set
         cb.tb_wen         <= 1'b0;
         cb.tb_hw_update   <= '0; //FIXME: With the prezumtion that HW events will be one clock cycle pulses
      endtask : write_seq

      task reset_seq(model_sfr_c sfr);
         fork
            //Thread 1 : Reset the DUT
            begin
               tb_rst_n = 0;
               repeat(2) @(posedge tb_clk);
               tb_rst_n = 1;
            end
            //Thread 2 : Reset the Model
            begin
               sfr.reset_sfr();
            end
         join
         //Synchronize with the clocking block
         @cb;
      endtask : reset_seq

      task disable_clock_seq(model_sfr_c sfr);
         fork
            //Thread 1 : Disable clock in the DUT
            begin
               cb.tb_clk_en <= 0;
            end
            //Thread 2 : Disable clock in the Model
            begin
               sfr.set_clk_en(1'b0);
            end
         join
         //Synchronize with the clocking block
         @cb;
      endtask : disable_clock_seq

      task enable_clock_seq(model_sfr_c sfr);
         fork
            //Thread 1 : Disable clock in the DUT
            begin
               cb.tb_clk_en <= 1;
            end
            //Thread 2 : Disable clock in the Model
            begin
               sfr.set_clk_en(1'b1);
            end
         join
         //Synchronize with the clocking block
         @cb;
      endtask : enable_clock_seq

      task reset_test(); //TODO if the sfr module will also support different reset values this should be updated accorddingly
         model_sfr_c sfr = new();
         logic [31:0] exp_rd1;
         logic [31:0] exp_rd2;

         //Synchronize with the posedge of tb_clk
         @(posedge tb_clk);
         //Reset sequence
         reset_seq(sfr);

         fork
            begin //DUT Read
               read_seq(ADDRESS);
            end
            begin //Model Read
               {exp_rd2, exp_rd1} = sfr.read_sfr(ADDRESS);
            end
         join

         check_outputs({dut_dout,dut_rdonly_dout}, {exp_rd2, exp_rd1});

         //Report results
         report_passrate();
      endtask : reset_test


      task clock_disable_test();
         model_sfr_c sfr = new();
         logic [31:0] exp_rd1;
         logic [31:0] exp_rd2;

         //Synchronize with the posedge of tb_clk
         @(posedge tb_clk);

         //////////////////////////////////////////////
         // Try to HW write data with clock disabled //
         //////////////////////////////////////////////

         //Disable the clock
         disable_clock_seq(sfr);

         //Write the data
         fork
            begin //DUT Write
               write_seq(ADDRESS,0,32'hFFFF_FFFF,32'hAAAA_AAAA,'0);
            end
            begin //Model Write
               sfr.write_sfr(ADDRESS,0,32'hFFFF_FFFF,32'hAAAA_AAAA,'0);
            end
         join

         //Read the data back
         fork
            begin //DUT Read
               read_seq(ADDRESS);
            end
            begin //Model Read
               {exp_rd2, exp_rd1} = sfr.read_sfr(ADDRESS);
            end
         join

         check_outputs({dut_dout,dut_rdonly_dout}, {exp_rd2, exp_rd1});
         
         //////////////////////////////////////////////
         //     SW write data with clock enabled     //
         //////////////////////////////////////////////

         //Enable the clock
         enable_clock_seq(sfr);

         //Write the data
         fork
            begin //DUT Write
               write_seq(ADDRESS,1,'0,'0,32'hAAAA_AAAA);
            end
            begin //Model Write
               sfr.write_sfr(ADDRESS,1,'0,'0,32'hAAAA_AAAA);
            end
         join

         //Read the data back
         fork
            begin //DUT Read
               read_seq(ADDRESS);
            end
            begin //Model Read
               {exp_rd2, exp_rd1} = sfr.read_sfr(ADDRESS);
            end
         join

         check_outputs({dut_dout,dut_rdonly_dout}, {exp_rd2, exp_rd1});

         //////////////////////////////////////////////
         // Try to SW write data with clock disabled //
         //////////////////////////////////////////////
         
         //Disable the clock
         disable_clock_seq(sfr);

         //Write the data
         fork
            begin //DUT Write
               write_seq(ADDRESS,1,'0,'0,32'h5555_5555);
            end
            begin //Model Write
               sfr.write_sfr(ADDRESS,1,'0,'0,32'h5555_5555);
            end
         join

         //Read the data back
         fork
            begin //DUT Read
               read_seq(ADDRESS);
            end
            begin //Model Read
               {exp_rd2, exp_rd1} = sfr.read_sfr(ADDRESS);
            end
         join

         check_outputs({dut_dout,dut_rdonly_dout}, {exp_rd2, exp_rd1});

         //Enable the clock
         enable_clock_seq(sfr);

         //Report results
         report_passrate();
      endtask : clock_disable_test


      task bit_bash_test();
         model_sfr_c sfr = new();
         logic [31:0] exp_rd1;
         logic [31:0] exp_rd2;

         //Reset sequence
         reset_seq(sfr);

         for (int reg_bit_idx = 0; reg_bit_idx < DATA_WIDTH; reg_bit_idx++) begin
            logic [DATA_WIDTH-1:0] data = '0;

            //Set the data as power of 2's to bash every bit in the register
            data = 2**reg_bit_idx;

            //Write the data
            fork
               begin //DUT Write
                  write_seq(ADDRESS,1,'0,'0,data);
               end
               begin //Model Write
                  sfr.write_sfr(ADDRESS,1,'0,'0,data);
               end
            join

            //Read the data back
            fork
               begin //DUT Read
                  read_seq(ADDRESS);
               end
               begin //Model Read
                  {exp_rd2, exp_rd1} = sfr.read_sfr(ADDRESS);
               end
            join

            check_outputs({dut_dout,dut_rdonly_dout}, {exp_rd2, exp_rd1});
         end

         //Report results
         report_passrate();
      endtask : bit_bash_test


      task write_read_all_test();
         model_sfr_c sfr = new();

         for (int reg_idx_write = 0; reg_idx_write < DATA_WIDTH; reg_idx_write++) begin
            logic [DATA_WIDTH-1:0] exp_rd1;
            logic [DATA_WIDTH-1:0] exp_rd2;
            logic [DATA_WIDTH-1:0] data;

            //Reset sequence
            reset_seq(sfr);

            data = $urandom();

            //Write the data
            fork
               begin //DUT Write
                  write_seq(ADDRESS,1,'0,'0,data);
               end
               begin //Model Write
                  sfr.write_sfr(ADDRESS,1,'0,'0,data);
               end
            join

            for (int reg_idx_read = 0; reg_idx_read < DATA_WIDTH; reg_idx_read++) begin
               //Read all the registers
               fork
                  begin //DUT Read
                     read_seq(ADDRESS);
                  end
                  begin //Model Read
                     {exp_rd2, exp_rd1} = sfr.read_sfr(ADDRESS);
                  end
               join
               
               check_outputs({dut_dout,dut_rdonly_dout}, {exp_rd2, exp_rd1});
            end
         end

         //Report results
         report_passrate();
      endtask : write_read_all_test


      task write_read_test();
         model_sfr_c sfr = new();

         //Reset sequence
         reset_seq(sfr);

         for (int reg_idx = 0; reg_idx < 32; reg_idx++) begin
            logic [31:0] exp_rd1;
            logic [31:0] exp_rd2;

            //Write Patterns
            //32'h0000_0000
            fork
               begin //DUT Write
                  write_seq(ADDRESS,1,'0,'0,32'h0000_0000);
               end
               begin //Model Write
                  sfr.write_sfr(ADDRESS,1,'0,'0,32'h0000_0000);
               end
            join

            fork
               begin //DUT Read
                  read_seq(ADDRESS);
               end
               begin //Model Read
                   {exp_rd2, exp_rd1} = sfr.read_sfr(ADDRESS);
                end
            join

            check_outputs({dut_dout,dut_rdonly_dout}, {exp_rd2, exp_rd1});

            //32'h5555_5555
            fork
               begin //DUT Write
                  write_seq(ADDRESS,1,'0,'0,32'h5555_5555);
               end
               begin //Model Write
                  sfr.write_sfr(ADDRESS,1,'0,'0,32'h5555_5555);
               end
            join

            fork
               begin //DUT Read
                  read_seq(ADDRESS);
               end
               begin //Model Read
                   {exp_rd2, exp_rd1} = sfr.read_sfr(ADDRESS);
                end
            join

            check_outputs({dut_dout,dut_rdonly_dout}, {exp_rd2, exp_rd1});

            //32'hAAAA_AAAA
            fork
               begin //DUT Write
                  write_seq(ADDRESS,1,'0,'0,32'hAAAA_AAAA);
               end
               begin //Model Write
                  sfr.write_sfr(ADDRESS,1,'0,'0,32'hAAAA_AAAA);
               end
            join

            fork
               begin //DUT Read
                  read_seq(ADDRESS);
               end
               begin //Model Read
                   {exp_rd2, exp_rd1} = sfr.read_sfr(ADDRESS);
                end
            join

            check_outputs({dut_dout,dut_rdonly_dout}, {exp_rd2, exp_rd1});

            //32'hFFFF_FFFF
            fork
               begin //DUT Write
                  write_seq(ADDRESS,1,'0,'0,32'hFFFF_FFFF);
               end
               begin //Model Write
                  sfr.write_sfr(ADDRESS,1,'0,'0,32'hFFFF_FFFF);
               end
            join

            fork
               begin //DUT Read
                  read_seq(ADDRESS);
               end
               begin //Model Read
                   {exp_rd2, exp_rd1} = sfr.read_sfr(ADDRESS);
                end
            join

            check_outputs({dut_dout,dut_rdonly_dout}, {exp_rd2, exp_rd1});

            //Write Random Values
            for (int i = 0; i < 100; i++) begin
               logic [DATA_WIDTH-1:0] data;

               data = $urandom();

               fork
                  begin //DUT Write
                     write_seq(ADDRESS,1,'0,'0,data);
                  end
                  begin //Model Write
                     sfr.write_sfr(ADDRESS,1,'0,'0,data);
                  end
               join

               fork
                  begin //DUT Read
                     read_seq(ADDRESS);
                  end
                  begin //Model Read
                     {exp_rd2, exp_rd1} = sfr.read_sfr(ADDRESS);
                  end
               join

               check_outputs({dut_dout,dut_rdonly_dout}, {exp_rd2, exp_rd1});
            end
            
         end

         //Report results
         report_passrate();
      endtask : write_read_test

      //TODO implement HW update tests (priority functionality etc)

   endclass : sfr_tests_c 

   //Define a clocking block for the input signals
   // Clocking block
   clocking cb @(posedge tb_clk);
      //Sample
      input dut_dout;
      input dut_rdonly_dout;
      //Drive
      output tb_clk_en;
      output tb_addr;
      output tb_wen;
      output tb_hw_update;
      output tb_hw_value;
      output tb_sw_value;    
   endclocking

   //Clock Generator Thread
   initial begin
      tb_clk <= 0;
      forever #5 tb_clk = !tb_clk;
   end

   //Run the tests
   initial begin
      //Create the test_sequence object
      sfr_tests_c test_sequence = new();

      //Synchronize with the posedge of tb_clk
      @(posedge tb_clk);

      $display("//+--------------------------------------------------------------+//");
      $display("//|                       Reset Test Start                       |//");
      $display("//+--------------------------------------------------------------+//");
      test_sequence.reset_test();

      $display("//+--------------------------------------------------------------+//");
      $display("//|                   Clock Disable Test Start                   |//");
      $display("//+--------------------------------------------------------------+//");
      test_sequence.clock_disable_test();

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

      $display("Stopping simulation.");
      $finish;
   end

endmodule : sfr_module_v1_tb