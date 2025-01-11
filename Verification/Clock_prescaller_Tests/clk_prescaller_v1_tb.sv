//######################################## Header ########################################
//# Author: Vlad Rosu                                                                    #
//# Description: Testbench for the prescaller module                                     #
//########################################################################################

module clk_prescaller_v1_tb #(
   parameter DIV_RES = 4
) ();

   //Packages and libraries
   import pkg_verification_utils::*;
   
   //Instantiate the DUT
   clk_prescaller_v1 #(
      .DIV_RESOLUTION(DIV_RES)
   ) dut(
   //    Input ports definition
      .sys_clk    ( tb_clk ),
      .sys_clk_en ( tb_clk_en ),
      .sys_rst_n  ( tb_rst_n ),
   //    Output ports definition
      .pclk_out   ( dut_pclk_out )
   );
   
   //DUT inputs
   bit                  tb_clk;
   bit                  tb_clk_en;
   bit                  tb_rst_n;
   
   //DUT outputs (used logic for outputs because logic is 4-state type)
   logic [DIV_RES-1:0]  dut_pclk_out;

   //TB utilities
   int unsigned   errors = 0;
   int unsigned   test_count = 0;

   //For debug waveform
   logic [DIV_RES-1:0]  debug_model_pclk;

   class model_clk_prescaller_c;
      //Class Properties
      local bit clk_en;
      local bit [DIV_RES-1:0] pclk_out;

      //Class Methods
      function new();
            this.clk_en = 1'b1; //by default the clock is enabled
            this.pclk_out = '0; //all clocks start from 0
            debug_model_pclk = this.pclk_out;
      endfunction : new

      function void set_clk_en(bit value);
         this.clk_en = value;
      endfunction : set_clk_en

      function bit [DIV_RES-1:0] get_pclk_out;
         return this.pclk_out;
         debug_model_pclk = this.pclk_out;
      endfunction : get_pclk_out

      function void reset();
         this.pclk_out = '0;
         debug_model_pclk = this.pclk_out;
      endfunction : reset

      function void increment();
         if(this.clk_en)
            this.pclk_out = this.pclk_out + 1'b1;
         debug_model_pclk = this.pclk_out;
      endfunction : increment
      
   endclass : model_clk_prescaller_c

   class clk_prescaller_tests_c;
      
      function void check_outputs(logic [DIV_RES-1:0] dut_out, logic [DIV_RES-1:0] expected);
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

      task reset_seq(model_clk_prescaller_c model);
         fork
            //Thread 1 : Reset the DUT
            begin
               tb_rst_n = 0;
               repeat(2) @(posedge tb_clk);
               tb_rst_n = 1;
            end
            //Thread 2 : Reset the Model
            begin
               model.reset();
            end
         join
         //Synchronize with the clocking block
         @cb;
      endtask : reset_seq

      task disable_clock_seq(model_clk_prescaller_c model);
         fork
            //Thread 1 : Disable clock in the DUT
            begin
               cb.tb_clk_en <= 0;
            end
            //Thread 2 : Disable clock in the Model
            begin
               model.set_clk_en(1'b0);
            end
         join
         //Synchronize with the clocking block
         @cb;
      endtask : disable_clock_seq

      task enable_clock_seq(model_clk_prescaller_c model);
         fork
            //Thread 1 : Disable clock in the DUT
            begin
               cb.tb_clk_en <= 1;
            end
            //Thread 2 : Disable clock in the Model
            begin
               model.set_clk_en(1'b1);
            end
         join
         //Synchronize with the clocking block
         @cb;
      endtask : enable_clock_seq

      task reset_test();
         model_clk_prescaller_c model = new();

         //Synchronize with the posedge of tb_clk
         @(posedge tb_clk);
         //Reset sequence
         reset_seq(model);

         check_outputs(dut_pclk_out, model.get_pclk_out());

         //Report results
         report_passrate();
      endtask : reset_test

      task clock_gating_test();
         model_clk_prescaller_c model = new();

         //Synchronize with the posedge of tb_clk
         @(posedge tb_clk);
         //Reset sequence
         reset_seq(model);

         fork
            //This thread updates the model every clock to stay in synch with the RTL
            begin
               forever begin
                  model.increment();
                  @(posedge tb_clk);
               end
            end
            //This thread contains the actual test logic
            begin
               //Disable clock
               disable_clock_seq(model);
               //Check the next 10 clocks
               repeat(10) begin
                  check_outputs(dut_pclk_out, model.get_pclk_out());
                  @cb;
               end

               //Enable clock
               enable_clock_seq(model);
               //Check the next 10 clocks
               repeat(10) begin
                  check_outputs(dut_pclk_out, model.get_pclk_out());
                  @cb;
               end

               //Disable clock
               disable_clock_seq(model);
               //Check the next 10 clocks
               repeat(1) begin
                  check_outputs(dut_pclk_out, model.get_pclk_out());
                  @cb;
               end

               //Enable clock
               enable_clock_seq(model);
               //Check the next 10 clocks
               repeat(1) begin
                  check_outputs(dut_pclk_out, model.get_pclk_out());
                  @cb;
               end
            end
         join_any

         //Report results
         report_passrate();

      endtask : clock_gating_test

      task base_functionalty_test();
          model_clk_prescaller_c model = new();

         //Synchronize with the posedge of tb_clk
         @(posedge tb_clk);
         //Reset sequence
         reset_seq(model);

         fork
            //This thread updates the model every clock to stay in synch with the RTL
            begin
               forever begin
                  model.increment();
                  @(posedge tb_clk);
               end
            end
            //This thread contains the actual test logic
            begin
               //Check every clock the output
               repeat(1000) begin
                  check_outputs(dut_pclk_out, model.get_pclk_out());
                  @cb;
               end
            end
         join_any

         //Report results
         report_passrate();

      endtask : base_functionalty_test

   endclass : clk_prescaller_tests_c 

   //Define a clocking block for the input signals
   // Clocking block
   clocking cb @(posedge tb_clk);
      //Sample
      input dut_pclk_out;
      //Drive
      output tb_clk_en;
   endclocking

   //Clock Generator Thread
   initial begin
      tb_clk <= 0;
      forever #5 tb_clk = !tb_clk;
   end

   //Run the tests
   initial begin
      //Create the test_sequence object
      clk_prescaller_tests_c test_sequence = new();

      //Tie the clock enable and reset for the DUT to 1
      tb_rst_n  = 1'b1;
      cb.tb_clk_en <= 1'b1;

      //Synchronize with the posedge of tb_clk
      @(posedge tb_clk);

      $display("//+--------------------------------------------------------------+//");
      $display("//|                       Reset Test Start                       |//");
      $display("//+--------------------------------------------------------------+//");
      test_sequence.reset_test();

      $display("//+--------------------------------------------------------------+//");
      $display("//|                   Clock Gating Test Start                    |//");
      $display("//+--------------------------------------------------------------+//");
      test_sequence.clock_gating_test();

      $display("//+--------------------------------------------------------------+//");
      $display("//|                  Functionality Test Start                    |//");
      $display("//+--------------------------------------------------------------+//");
      test_sequence.base_functionalty_test();

      $display("Stopping simulation.");
      $finish;
   end

endmodule : clk_prescaller_v1_tb