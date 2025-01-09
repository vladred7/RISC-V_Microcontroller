module dco_nbit_v1_tb#(
   parameter DATA_WIDTH = 32,
   parameter N = 20
) ();

   //Packages and libraries
   import pkg_verification_utils::*;
   
   //Instantiate the DUT
   dco_nbit_v1 #(
      .DATA_WIDTH(DATA_WIDTH),
      .N(N)
   ) dut(
      //    Input ports definition
      .sys_clk          ( tb_dut_clk            ),
      .sys_clk_en       ( tb_clk_en             ),
      .sys_rst_n        ( tb_rst_n              ),
      .dco_ctrl         ( tb_dco_ctrl_sfr       ),
      .dco_cnt          ( tb_dco_cnt_sfr        ),
      //    Output ports definition
      .hw_up_dco_ctrl   ( dut_hw_up_dco_ctrl    ),
      .hw_up_dco_cnt    ( dut_hw_up_dco_cnt     ),
      .hw_val_dco_ctrl  ( dut_hw_val_dco_ctrl   ),
      .hw_val_dco_cnt   ( dut_hw_val_dco_cnt    ),
      .dco_clk_out      ( dut_dco_clk_out       )
   );
   
   //DUT inputs
   bit                     tb_dut_clk;
   bit                     tb_clk_en;
   bit                     tb_rst_n;
   bit   [DATA_WIDTH-1:0]  tb_dco_ctrl_sfr;
   bit   [DATA_WIDTH-1:0]  tb_dco_cnt_sfr;
   
   //DUT outputs (used logic for outputs because logic is 4-state type)
   logic [DATA_WIDTH-1:0]  dut_hw_up_dco_ctrl;
   logic [DATA_WIDTH-1:0]  dut_hw_up_dco_cnt;
   logic [DATA_WIDTH-1:0]  dut_hw_val_dco_ctrl;
   logic [DATA_WIDTH-1:0]  dut_hw_val_dco_cnt;
   logic                   dut_dco_clk_out;

   //TB utilities
   int unsigned   errors = 0;
   int unsigned   test_count = 0;
   bit                     tb_clk;
   bit              [3:0]  tb_clk_div;
   bit                     tb_dut_clk_dly;
   bit                     tb_dut_posedge_detect;
   bit                     tb_dut_negedge_detect;

   //For debug waveform
   logic                   debug_clk_en;
   logic                   debug_model_dco_clk;
   logic          [N-1:0]  debug_model_dco_tmr_val;

   class model_dco_c;
      //Class Properties
      local bit                  clk_en;
      local bit [DATA_WIDTH-1:0] hw_up_dco_ctrl;
      local bit [DATA_WIDTH-1:0] hw_up_dco_cnt;
      local bit [DATA_WIDTH-1:0] hw_val_dco_ctrl;
      local bit [DATA_WIDTH-1:0] hw_val_dco_cnt;
      local bit                  dco_clk_out;
      local bit          [N-1:0] dco_tmr_val;

      //Class Methods
      function new();
         this.clk_en             = 1'b1; //by default the clock is enabled
         this.hw_up_dco_ctrl     =   '0;
         this.hw_up_dco_cnt      =   '0;
         this.hw_val_dco_ctrl    =   '0;
         this.hw_val_dco_cnt     =   '0;
         this.dco_clk_out        = 1'b0; //output clock starts from 0
         this.dco_tmr_val        =   '0;
         debug_clk_en = this.clk_en;
      endfunction : new

      //This function should update in the clock domain of the module
      function void set_clk_en();
         this.clk_en = tb_clk_en;
         debug_clk_en = this.clk_en;
      endfunction : set_clk_en

      function bit get_dco_clk_out();
         return this.dco_clk_out;
      endfunction : get_dco_clk_out

      //This function should update in the clock domain of the module
      function void reset();
         this.dco_clk_out = 1'b0;
         debug_model_dco_clk = this.dco_clk_out;
         this.dco_tmr_val =   '0;
         debug_model_dco_tmr_val = this.dco_tmr_val;
      endfunction : reset

      //This function should update in the clock domain of the module
      function void update_dco_clk_out();
         if(this.clk_en && tb_dco_ctrl_sfr[0] && tb_rst_n) begin //ON = 1 & Reset inactive
            //When SFR values is hit then toggle the output and clear the timer
            if(this.dco_tmr_val === tb_dco_cnt_sfr[N-1:0]) begin
               this.dco_clk_out = !this.dco_clk_out;
               debug_model_dco_clk = this.dco_clk_out;
               this.dco_tmr_val = '0;
            end else begin
               this.dco_tmr_val = this.dco_tmr_val + 1;
            end
            debug_model_dco_tmr_val = this.dco_tmr_val;
         end

      endfunction : update_dco_clk_out
      
   endclass : model_dco_c

   class dco_tests_c;
      
      function void check_outputs(logic dut_out, logic expected);
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

      task reset_seq(model_dco_c model);
         fork
            //Thread 1 : Reset the DUT
            begin
               tb_rst_n = 0;
               repeat(2) @(posedge tb_clk);
               tb_rst_n = 1;
            end
            //Thread 2 : Reset the Model
            begin
               fork
                  //Model main thread for reset
                  begin
                     model.reset();
                     repeat(2) @(posedge tb_clk);
                     model.reset();
                  end
                  //Thread that spwan to eventually sample the clock gate signal
                  begin
                     @(negedge tb_dut_clk_dly);
                     model.set_clk_en();
                  end
               join_any
               
            end
         join
      endtask : reset_seq

      task disable_clock_seq();
         cb_n.tb_clk_en <= 0;
      endtask : disable_clock_seq

      task enable_clock_seq();
         cb_n.tb_clk_en <= 1;
      endtask : enable_clock_seq

      task reset_test();
         model_dco_c model = new();

         //Synchronize with the posedge of tb_clk
         @(posedge tb_clk);
         //Reset sequence
         reset_seq(model);

         check_outputs(dut_dco_clk_out, model.get_dco_clk_out());

         //Report results
         report_passrate();
      endtask : reset_test

      task clock_gating_test();
         model_dco_c model = new();

         //Synchronize with the posedge of tb_clk
         @(posedge tb_clk);
         //Reset sequence
         reset_seq(model);

         fork
            //This thread updates the model every clock to stay in synch with the RTL
            begin
               forever begin
                  @(posedge tb_dut_clk_dly); //posedge of cb_tb_dut_clk
                  model.update_dco_clk_out();
                  @(negedge tb_dut_clk_dly); //negedge of cb_tb_dut_clk
                  model.set_clk_en(); //clock gate cell is update on the negedge of the clock is gating
               end
            end
            //This thread contains the actual test logic
            begin
               //Disable clock
               disable_clock_seq();
               //Check the next 10 clocks
               repeat(10) begin
                  check_outputs(dut_dco_clk_out, model.get_dco_clk_out());
                  @cb;
               end

               //Enable clock
               enable_clock_seq();
               //Check the next 10 clocks
               repeat(10) begin
                  check_outputs(dut_dco_clk_out, model.get_dco_clk_out());
                  @cb;
               end

               //Disable clock
               disable_clock_seq();
               //Check the next 10 clocks
               repeat(1) begin
                  check_outputs(dut_dco_clk_out, model.get_dco_clk_out());
                  @cb;
               end

               //Enable clock
               enable_clock_seq();
               //Check the next 10 clocks
               repeat(1) begin
                  check_outputs(dut_dco_clk_out, model.get_dco_clk_out());
                  @cb;
               end
            end
         join_any

         //Report results
         report_passrate();

      endtask : clock_gating_test

      task base_functionalty_test();
          model_dco_c model = new();

         //Synchronize with the posedge of tb_clk
         @(posedge tb_clk);
         //Reset sequence
         reset_seq(model);

         fork
            //This thread updates the model every clock to stay in synch with the RTL
            begin
               forever begin
                  @(posedge tb_dut_clk_dly); //posedge of cb_tb_dut_clk
                  model.update_dco_clk_out();
                  @(negedge tb_dut_clk_dly); //negedge of cb_tb_dut_clk
                  model.set_clk_en(); //clock gate cell is update on the negedge of the clock is gating
               end
            end
            //This thread contains the actual test logic
            begin
               //Check every clock the output
               repeat(1000) begin
                  check_outputs(dut_dco_clk_out, model.get_dco_clk_out());
                  @cb;
               end
            end
         join_any

         //Report results
         report_passrate();

      endtask : base_functionalty_test

   endclass : dco_tests_c 

   //Define a clocking block for the input signals
   // Clocking block
   clocking cb @(posedge tb_clk);
      //Sample
      input dut_hw_up_dco_ctrl;
      input dut_hw_up_dco_cnt;
      input dut_hw_val_dco_ctrl;
      input dut_hw_val_dco_cnt;
      input dut_dco_clk_out;
      //Drive
      output tb_dco_ctrl_sfr;
      output tb_dco_cnt_sfr;
   endclocking

   // Clocking block on negedge
   clocking cb_n @(negedge tb_clk);
      //Drive
      output tb_clk_en;
   endclocking

   //System Clock Generator Thread
   initial begin
      tb_clk      <=  0;
      forever #500ns tb_clk = !tb_clk;
   end
   //Divided Clocks Generator Thread
   always @(posedge tb_clk) tb_clk_div <= tb_clk_div + 1;

   //Testbench clock is selected by the clksrc bits in the dco_ctrl_sfr
   always @(*) begin
      case (tb_dco_ctrl_sfr[10:8]) //CLKSRC[2:0]
         3'b000:  tb_dut_clk <= tb_clk;
         3'b001:  tb_dut_clk <= tb_clk_div[0];
         3'b010:  tb_dut_clk <= tb_clk_div[1];
         3'b011:  tb_dut_clk <= tb_clk_div[2];
         3'b100:  tb_dut_clk <= tb_clk_div[3];
         default: tb_dut_clk <= tb_clk;
      endcase
   end
   
   assign #1ns tb_dut_clk_dly = tb_dut_clk;

   //Run the tests
   initial begin
      //Create the test_sequence object
      dco_tests_c test_sequence = new();
      int num_of_cfgs = 10;
      bit [DATA_WIDTH-1:0] dco_cnt_sfr_val;
      bit [DATA_WIDTH-1:0] dco_ctrl_sfr_val;

      //Tie the clock enable and reset for the DUT to 1
      tb_rst_n  = 1'b1;
      cb_n.tb_clk_en <= 1'b1;

      for (int i = 0; i < num_of_cfgs; i++) begin
         case (i)
            0: {dco_cnt_sfr_val,dco_ctrl_sfr_val} = {32'h0000_0007,32'h0000_0001}; //CNT =  7, CLK=000, ON
            1: {dco_cnt_sfr_val,dco_ctrl_sfr_val} = {32'h0000_0007,32'h0000_0000}; //CNT =  7, CLK=000, OFF
            2: {dco_cnt_sfr_val,dco_ctrl_sfr_val} = {32'h0000_0006,32'h0000_0101}; //CNT =  6, CLK=001, ON
            3: {dco_cnt_sfr_val,dco_ctrl_sfr_val} = {32'h0000_0005,32'h0000_0201}; //CNT =  5, CLK=010, ON
            4: {dco_cnt_sfr_val,dco_ctrl_sfr_val} = {32'h0000_0004,32'h0000_0301}; //CNT =  4, CLK=011, ON
            5: {dco_cnt_sfr_val,dco_ctrl_sfr_val} = {32'h0000_0003,32'h0000_0401}; //CNT =  3, CLK=100, ON
            6: {dco_cnt_sfr_val,dco_ctrl_sfr_val} = {32'h0000_0003,32'h0000_0400}; //CNT =  3, CLK=100, OFF
            7: {dco_cnt_sfr_val,dco_ctrl_sfr_val} = {32'h0000_0003,32'h0000_0401}; //CNT = 10, CLK=111, ON
            8: {dco_cnt_sfr_val,dco_ctrl_sfr_val} = {32'h000F_FFFF,32'h0000_0001}; //CNT =MAX, CLK=000, ON
            default : begin
               bit [2:0] clk_sel;
               dco_cnt_sfr_val = $urandom_range(0,10);
               clk_sel = $urandom();
               dco_ctrl_sfr_val = {21'b0,clk_sel,7'b0,1'b1};
            end
         endcase

         $display("Configuration:",);
         $display("dco_cnt_sfr = %0h",dco_cnt_sfr_val);
         $display("dco_ctrl_sfr = %0h",dco_ctrl_sfr_val);

         cb.tb_dco_cnt_sfr  <= dco_cnt_sfr_val;
         cb.tb_dco_ctrl_sfr <= dco_ctrl_sfr_val;

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
      end

      $display("Stopping simulation.");
      $finish;
   end

endmodule : dco_nbit_v1_tb