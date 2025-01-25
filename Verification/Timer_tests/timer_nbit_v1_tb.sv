//######################################## Header ########################################
//# Author: Vlad Rosu                                                                    #
//# Description: Tesetbench for the timer module                                         #
//########################################################################################

module timer_nbit_v1_tb#(
   parameter DATA_WIDTH = 32,
   parameter ADDR_WIDTH = 32,
   parameter BASE_ADDR  =  0,
   parameter N = 32
) ();

   //Packages and libraries
   import pkg_verification_utils::*;
   import pkg_sfrs_definition::*;

   //Local Parameters
   localparam int TMR_CTRL_ADDR  =          BASE_ADDR;
   localparam int TMR_VAL_ADDR   =  TMR_CTRL_ADDR + 1;
   localparam int TMR_MVAL0_ADDR =   TMR_VAL_ADDR + 1;
   localparam int TMR_MVAL1_ADDR = TMR_MVAL0_ADDR + 1;

   //Instantiate the real SFRs of the module
   sfr_module_v1 #(
      .SFR_ADDR_WIDTH(ADDR_WIDTH),
      .SFR_WIDTH(DATA_WIDTH),
      .SFR_ADDRESS(TMR_CTRL_ADDR),
      .IMPLEMENTED_BITS_MASK(32'h00E0_E7CF),
      .READABLE_BITS_MASK(32'h00E0_E701),
      .SW_UPDATABLE_BITS_MASK(32'h00E0_E7CF),
      .HW_UPDATABLE_BITS_MASK(32'h0000_E0CE)
   ) tmr_ctrl_sfr(
      //    Input ports
      .sys_clk          ( tb_clk                ),
      .sys_clk_en       ( tb_clk_en             ),
      .sys_rst_n        ( tb_rst_n              ),
      .sys_addr         ( tb_addr               ),
      .sys_wr_en        ( tb_wen                ),
      .sfr_hw_upate     ( dut_hw_up_tmr_ctrl    ),
      .sfr_hw_value     ( dut_hw_val_tmr_ctrl   ),
      .sfr_sw_value     ( tb_wr_data_bus        ),
      //    Output ports
      .sfr_dout         ( tmr_ctrl_sfr_out      ),
      .sfr_rdonly_dout  (                       )
   );

   sfr_module_v1 #(
      .SFR_ADDR_WIDTH(ADDR_WIDTH),
      .SFR_WIDTH(DATA_WIDTH),
      .SFR_ADDRESS(TMR_VAL_ADDR),
      .IMPLEMENTED_BITS_MASK(32'hFFFF_FFFF),
      .READABLE_BITS_MASK(32'hFFFF_FFFF),
      .SW_UPDATABLE_BITS_MASK(32'hFFFF_FFFF),
      .HW_UPDATABLE_BITS_MASK(32'hFFFF_FFFF)
   ) tmr_val_sfr(
      //    Input ports
      .sys_clk          ( tb_clk                ),
      .sys_clk_en       ( tb_clk_en             ),
      .sys_rst_n        ( tb_rst_n              ),
      .sys_addr         ( tb_addr               ),
      .sys_wr_en        ( tb_wen                ),
      .sfr_hw_upate     ( dut_hw_up_tmr_val     ),
      .sfr_hw_value     ( dut_hw_val_tmr_val    ),
      .sfr_sw_value     ( tb_wr_data_bus        ),
      //    Output ports
      .sfr_dout         ( tmr_val_sfr_out       ),
      .sfr_rdonly_dout  (                       )
   );

   sfr_module_v1 #(
      .SFR_ADDR_WIDTH(ADDR_WIDTH),
      .SFR_WIDTH(DATA_WIDTH),
      .SFR_ADDRESS(TMR_MVAL0_ADDR),
      .IMPLEMENTED_BITS_MASK(32'hFFFF_FFFF),
      .READABLE_BITS_MASK(32'hFFFF_FFFF),
      .SW_UPDATABLE_BITS_MASK(32'hFFFF_FFFF),
      .HW_UPDATABLE_BITS_MASK(32'h0000_0000)
   ) tmr_mval0_sfr(
      //    Input ports
      .sys_clk          ( tb_clk                ),
      .sys_clk_en       ( tb_clk_en             ),
      .sys_rst_n        ( tb_rst_n              ),
      .sys_addr         ( tb_addr               ),
      .sys_wr_en        ( tb_wen                ),
      .sfr_hw_upate     ( dut_hw_up_tmr_mval0   ),
      .sfr_hw_value     ( dut_hw_val_tmr_mval0  ),
      .sfr_sw_value     ( tb_wr_data_bus        ),
      //    Output ports
      .sfr_dout         ( tmr_mval0_sfr_out     ),
      .sfr_rdonly_dout  (                       )
   );

   sfr_module_v1 #(
      .SFR_ADDR_WIDTH(ADDR_WIDTH),
      .SFR_WIDTH(DATA_WIDTH),
      .SFR_ADDRESS(TMR_MVAL1_ADDR),
      .IMPLEMENTED_BITS_MASK(32'hFFFF_FFFF),
      .READABLE_BITS_MASK(32'hFFFF_FFFF),
      .SW_UPDATABLE_BITS_MASK(32'hFFFF_FFFF),
      .HW_UPDATABLE_BITS_MASK(32'h0000_0000)
   ) tmr_mval1_sfr(
      //    Input ports
      .sys_clk          ( tb_clk                ),
      .sys_clk_en       ( tb_clk_en             ),
      .sys_rst_n        ( tb_rst_n              ),
      .sys_addr         ( tb_addr               ),
      .sys_wr_en        ( tb_wen                ),
      .sfr_hw_upate     ( dut_hw_up_tmr_mval1   ),
      .sfr_hw_value     ( dut_hw_val_tmr_mval1  ),
      .sfr_sw_value     ( tb_wr_data_bus        ),
      //    Output ports
      .sfr_dout         ( tmr_mval1_sfr_out     ),
      .sfr_rdonly_dout  (                       )
   );
   
   //Instantiate the DUT
   timer_nbit_v1 #(
      .DATA_WIDTH(DATA_WIDTH),
      .N(N)
   ) dut(
      //    Input ports definition
      .sys_clk                ( tb_dut_clk            ),
      .sys_clk_en             ( tb_clk_en             ),
      .sys_rst_n              ( tb_rst_n              ),
      .tmr_ctrl               ( tmr_ctrl_sfr_out      ),
      .tmr_val                ( tmr_val_sfr_out       ),
      .tmr_match_val0         ( tmr_mval0_sfr_out     ),
      .tmr_match_val1         ( tmr_mval1_sfr_out     ), 
      //    Output ports definition
      .hw_up_tmr_ctrl         ( dut_hw_up_tmr_ctrl    ),
      .hw_up_tmr_val          ( dut_hw_up_tmr_val     ),
      .hw_up_tmr_match_val0   ( dut_hw_up_tmr_mval0   ),
      .hw_up_tmr_match_val1   ( dut_hw_up_tmr_mval1   ),
      .hw_val_tmr_ctrl        ( dut_hw_val_tmr_ctrl   ),
      .hw_val_tmr_val         ( dut_hw_val_tmr_val    ),
      .hw_val_tmr_match_val0  ( dut_hw_val_tmr_mval0  ),
      .hw_val_tmr_match_val1  ( dut_hw_val_tmr_mval1  ),
      .match0_event           ( dut_match0_event      ),
      .match1_event           ( dut_match1_event      ),
      .ovf_event              ( dut_ovf_event         ) 
   );
   
   //DUT inputs
   bit                     tb_dut_clk;
   bit                     tb_clk_en;
   bit                     tb_rst_n;
   //These signals comes from the actual implemented SFR modules
   tmr_ctrl_t              tmr_ctrl_sfr_out;
   tmr_val_t               tmr_val_sfr_out;
   tmr_match_val0_t        tmr_mval0_sfr_out;
   tmr_match_val1_t        tmr_mval1_sfr_out;

   //DUT outputs (used logic for outputs because logic is 4-state type)
   logic [DATA_WIDTH-1:0]  dut_hw_up_tmr_ctrl;
   logic [DATA_WIDTH-1:0]  dut_hw_up_tmr_val;
   logic [DATA_WIDTH-1:0]  dut_hw_up_tmr_mval0;
   logic [DATA_WIDTH-1:0]  dut_hw_up_tmr_mval1;
   logic [DATA_WIDTH-1:0]  dut_hw_val_tmr_ctrl;
   logic [DATA_WIDTH-1:0]  dut_hw_val_tmr_val;
   logic [DATA_WIDTH-1:0]  dut_hw_val_tmr_mval0;
   logic [DATA_WIDTH-1:0]  dut_hw_val_tmr_mval1;
   logic                   dut_match0_event;
   logic                   dut_match1_event;
   logic                   dut_ovf_event;

   //For debug waveform
   logic [DATA_WIDTH-1:0]  dbg_hw_up_tmr_ctrl;
   logic [DATA_WIDTH-1:0]  dbg_hw_up_tmr_val;
   logic [DATA_WIDTH-1:0]  dbg_hw_up_tmr_mval0;
   logic [DATA_WIDTH-1:0]  dbg_hw_up_tmr_mval1;
   logic [DATA_WIDTH-1:0]  dbg_hw_val_tmr_ctrl;
   logic [DATA_WIDTH-1:0]  dbg_hw_val_tmr_val;
   logic [DATA_WIDTH-1:0]  dbg_hw_val_tmr_mval0;
   logic [DATA_WIDTH-1:0]  dbg_hw_val_tmr_mval1;
   logic                   dbg_match0_ev;
   logic                   dbg_match1_ev;
   logic                   dbg_ovf_ev;
   logic                   dbg_rst_bit;
   logic                   dbg_ld_bit;
   logic                   dbg_start_bit;
   logic                   dbg_stop_bit;
   logic          [N-1:0]  dbg_tmr;
   logic                   dbg_match0;
   logic                   dbg_match1;
   logic                   dbg_ovf;
   logic                   dbg_q_ovf_ev;
   logic                   dbg_q_rst_bit;
   logic                   dbg_q_ld_bit;
   logic                   dbg_q_start_bit;
   logic                   dbg_q_stop_bit;
   logic          [N-1:0]  dbg_q_tmr;
   logic                   dbg_q_match0;
   logic                   dbg_q_match1;
   logic                   dbg_q_ovf;

   //TB utilities
   int unsigned            errors = 0;
   int unsigned            test_count = 0;
   bit                     tb_clk;
   bit              [3:0]  tb_clk_div;
   bit                     tb_model_clk;
   bit                     enable_model_clk;
   bit   [ADDR_WIDTH-1:0]  tb_addr;
   bit                     tb_wen;
   bit   [DATA_WIDTH-1:0]  tb_wr_data_bus;


   task front_door_write_sfr(bit [ADDR_WIDTH-1:0] addr, bit [DATA_WIDTH-1:0] data);
      cb.tb_addr        <= addr; //Put address on the addr bus
      cb.tb_wr_data_bus <= data; //Put data on the data bus
      cb.tb_wen         <= 1'b1; //Assert wen
      @cb;                       //Wait for the posedge to sample the data in the SFRs
      cb.tb_wen         <= 1'b0; //Deassert wen
      @cb;
   endtask : front_door_write_sfr

   //This function should be used carefully because it does not take into account the implemented bits masks
   task back_door_write_sfr(bit [ADDR_WIDTH-1:0] addr, bit [DATA_WIDTH-1:0] data);
      //Force value into the SFR
      case (addr)
         0: force tmr_ctrl_sfr.sfr_value_ff  = data;
         1: force tmr_val_sfr.sfr_value_ff   = data;
         2: force tmr_mval0_sfr.sfr_value_ff = data;
         3: force tmr_mval1_sfr.sfr_value_ff = data;
         default : $fatal("SFR with address = %0h does not exists!!!",addr);
      endcase
      //Immediately release the nets to not affect future logic that may update them
      release tmr_ctrl_sfr.sfr_value_ff;
      release tmr_val_sfr.sfr_value_ff;
      release tmr_mval0_sfr.sfr_value_ff;
      release tmr_mval1_sfr.sfr_value_ff;
   endtask : back_door_write_sfr

   class model_tmr_c;
      //Class Properties
      //IP outputs
      bit [DATA_WIDTH-1:0] hw_up_tmr_ctrl;
      bit [DATA_WIDTH-1:0] hw_up_tmr_val;
      bit [DATA_WIDTH-1:0] hw_up_tmr_mval0;
      bit [DATA_WIDTH-1:0] hw_up_tmr_mval1;
      bit [DATA_WIDTH-1:0] hw_val_tmr_ctrl;
      bit [DATA_WIDTH-1:0] hw_val_tmr_val;
      bit [DATA_WIDTH-1:0] hw_val_tmr_mval0;
      bit [DATA_WIDTH-1:0] hw_val_tmr_mval1;
      bit                  match0_ev;
      bit                  match1_ev;
      bit                  ovf_ev,     q_ovf_ev;
      //Model Internal logic
      bit                  rst_bit,    q_rst_bit;
      bit                  ld_bit,     q_ld_bit;
      bit                  start_bit,  q_start_bit;
      bit                  stop_bit,   q_stop_bit;
      bit                  count,      q_count;
      bit          [N:0]   tmr,        q_tmr; //note make the timer N+1 bits so it can detect overflow easier
      bit                  match0,     q_match0;
      bit                  match1,     q_match1;
      bit                  ovf,        q_ovf;


      //Class Methods
      function void hard_reset();
         this.hw_up_tmr_ctrl    = {17'b0,(tmr_mval1_sfr_out === 0),(tmr_mval0_sfr_out === 0),13'b0};
         this.hw_up_tmr_val     = '0;
         this.hw_up_tmr_mval0   = '0;
         this.hw_up_tmr_mval1   = '0;
         this.hw_val_tmr_ctrl   = 32'h0000_E000;
         this.hw_val_tmr_val    = '0;
         this.hw_val_tmr_mval0  = '0;
         this.hw_val_tmr_mval1  = '0;
         this.match0_ev         = '0;
         this.match1_ev         = '0;
         this.ovf_ev            = '0;
         this.q_ovf_ev          = '0;
         this.rst_bit           = '0;
         this.q_rst_bit         = '0;
         this.ld_bit            = '0;
         this.q_ld_bit          = '0;
         this.start_bit         = '0;
         this.q_start_bit       = '0;
         this.stop_bit          = '0;
         this.q_stop_bit        = '0;
         this.tmr               = '0;
         this.q_tmr             = '0;
         this.match0            = (tmr_mval0_sfr_out === 0); //set only if match0 sfr = 0
         this.q_match0          = '0;
         this.match1            = (tmr_mval1_sfr_out === 0); //set only if match1 sfr = 0
         this.q_match1          = '0;
         this.ovf               = '0;
         this.q_ovf             = '0;
      endfunction : hard_reset

      function void update_clk_posedge();
         q_ovf_ev     = ovf_ev;
         q_rst_bit    = rst_bit;
         q_ld_bit     = ld_bit;
         q_start_bit  = start_bit;
         q_stop_bit   = stop_bit;
         q_count      = count;
         q_tmr        = tmr;
         q_match0     = match0;
         q_match1     = match1;
         q_ovf        = ovf;
      endfunction : update_clk_posedge

      function void update_timer();
         count      = (stop_bit)   ? 1'b0   :
                      (start_bit)  ? 1'b1   :
                                     q_count;
                        
         if(tb_rst_n) begin
            if((rst_bit & q_rst_bit) | q_ovf)
               tmr = '0;
            else if(ld_bit) 
               tmr = tmr_val_sfr_out.tmr_val;
            else if(q_count | count)
               tmr = q_tmr + 1;
            else
               tmr = q_tmr;
         end
      endfunction : update_timer

      function void update_match_event_outputs();
         match0 = (q_tmr === tmr_mval0_sfr_out);
         match1 = (q_tmr === tmr_mval1_sfr_out);
         ovf    = (q_tmr[N] === 1'b1);
         if(tb_rst_n) begin
            match0_ev = q_match0 && tmr_ctrl_sfr_out.match0_en;
            match1_ev = q_match1 && tmr_ctrl_sfr_out.match1_en;
            ovf_ev    = q_ovf    && tmr_ctrl_sfr_out.ovf_en;
         end
      endfunction : update_match_event_outputs

      function void update_sfr_field_values();
         rst_bit    = tmr_ctrl_sfr_out.rst;
         ld_bit     = tmr_ctrl_sfr_out.ld;
         start_bit  = tmr_ctrl_sfr_out.start;
         stop_bit   = tmr_ctrl_sfr_out.stop;
      endfunction : update_sfr_field_values

      function void update_hw_up_out();
         hw_up_tmr_ctrl  = {
            8'b0,
            8'b0,
            ovf, match1, match0, 5'b0,
            (tmr_ctrl_sfr_out.start & (q_count | count)),
            (tmr_ctrl_sfr_out.stop & (~(q_count | count))),
            2'b0, tmr_ctrl_sfr_out.rd, q_ld_bit, (rst_bit & q_rst_bit), 1'b0
         };
         hw_up_tmr_val   = {32{tmr_ctrl_sfr_out.rd}};
         hw_up_tmr_mval0 = '0;
         hw_up_tmr_mval1 = '0;
      endfunction : update_hw_up_out
      
      function void update_hw_val_out();
         hw_val_tmr_ctrl  = 32'h0000_E000;
         hw_val_tmr_val   = q_tmr[31:0];
         hw_val_tmr_mval0 = '0;
         hw_val_tmr_mval1 = '0;
      endfunction : update_hw_val_out

      function void update_combo_logic();
         update_sfr_field_values();
         update_timer();
         update_match_event_outputs();
         update_hw_val_out();
         update_hw_up_out();
         
         debug_wfm_signals();
      endfunction : update_combo_logic

      function void debug_wfm_signals();
         dbg_hw_up_tmr_ctrl   = hw_up_tmr_ctrl;
         dbg_hw_up_tmr_val    = hw_up_tmr_val;
         dbg_hw_up_tmr_mval0  = hw_up_tmr_mval0;
         dbg_hw_up_tmr_mval1  = hw_up_tmr_mval1;
         dbg_hw_val_tmr_ctrl  = hw_val_tmr_ctrl;
         dbg_hw_val_tmr_val   = hw_val_tmr_val;
         dbg_hw_val_tmr_mval0 = hw_val_tmr_mval0;
         dbg_hw_val_tmr_mval1 = hw_val_tmr_mval1;
         dbg_match0_ev        = match0_ev;
         dbg_match1_ev        = match1_ev;
         dbg_ovf_ev           = ovf_ev;
         dbg_rst_bit          = rst_bit;
         dbg_ld_bit           = ld_bit;
         dbg_start_bit        = start_bit;
         dbg_stop_bit         = stop_bit;
         dbg_tmr              = tmr;
         dbg_match0           = match0;
         dbg_match1           = match1;
         dbg_ovf              = ovf;
         dbg_q_ovf_ev         = q_ovf_ev;
         dbg_q_rst_bit        = q_rst_bit;
         dbg_q_ld_bit         = q_ld_bit;
         dbg_q_start_bit      = q_start_bit;
         dbg_q_stop_bit       = q_stop_bit ;
         dbg_q_tmr            = q_tmr;
         dbg_q_match0         = q_match0;
         dbg_q_match1         = q_match1;
         dbg_q_ovf            = q_ovf;
      endfunction : debug_wfm_signals

   endclass : model_tmr_c

   class tmr_std_tests_c;

      function void check_outputs(logic[DATA_WIDTH-1:0] dut_out, logic[DATA_WIDTH-1:0] expected, string sig_name);
         if(dut_out !== expected) begin
            errors++;
            $display("ERROR on %s!!! -> Time %0t: expected=%0h, dut_out=%0h",sig_name, $time(), expected, dut_out);
         end

         test_count++; //increment test_count for each test
      endfunction : check_outputs

      function void check_all(model_tmr_c mod);
         check_outputs({dut_match0_event, dut_match1_event, dut_ovf_event}, 
                       {mod.match0_ev, mod.match1_ev, mod.ovf_ev}, "events outputs");
         check_outputs(dut_hw_up_tmr_ctrl  , mod.hw_up_tmr_ctrl  , "hw_up_tmr_ctrl");
         check_outputs(dut_hw_up_tmr_val   , mod.hw_up_tmr_val   , "hw_up_tmr_val");
         check_outputs(dut_hw_up_tmr_mval0 , mod.hw_up_tmr_mval0 , "hw_up_tmr_mval0");
         check_outputs(dut_hw_up_tmr_mval1 , mod.hw_up_tmr_mval1 , "hw_up_tmr_mval1");
         check_outputs(dut_hw_val_tmr_ctrl , mod.hw_val_tmr_ctrl , "hw_val_tmr_ctrl");
         check_outputs(dut_hw_val_tmr_val  , mod.hw_val_tmr_val  , "hw_val_tmr_val");
         check_outputs(dut_hw_val_tmr_mval0, mod.hw_val_tmr_mval0, "hw_val_tmr_mval0");
         check_outputs(dut_hw_val_tmr_mval1, mod.hw_val_tmr_mval1, "hw_val_tmr_mval1");
      endfunction : check_all

      function void report_passrate();
         $display("Pass Rate: %3.2f%%",((test_count-errors)/real'(test_count))*100);
         //After each report clear the number of tests and errors
         test_count = 0;
         errors = 0;
      endfunction : report_passrate
      
      task reset_test_seq(model_tmr_c mod);
         //Assert reset
         tb_rst_n = 1'b0;
         mod.hard_reset();
         mod.debug_wfm_signals();
         @(negedge tb_clk);
         //Check mid reset
         check_all(mod);
         @(negedge tb_clk);
         tb_rst_n = 1'b1;
         //Synchronize after reset
         @cb;
         //Check after reset
         check_all(mod);
      endtask : reset_test_seq

      task base_functionality_test_seq(
         bit [DATA_WIDTH-1:0]    tmr_ctrl_value,
         bit [DATA_WIDTH-1:0]    tmr_val_value,
         bit [DATA_WIDTH-1:0]    tmr_mval0_value,
         bit [DATA_WIDTH-1:0]    tmr_mval1_value,
         model_tmr_c             mod
         );
         logic [2:0] clk_src;
         int unsigned period;

         clk_src = tmr_ctrl_value[10:8];
         //Assign the period value the longest period between the 2 matches
         if(tmr_mval0_value > tmr_mval1_value)
            period = tmr_mval0_value[31:0];
         else
            period = tmr_mval1_value[31:0];

         //Disable the module
         front_door_write_sfr(0, 32'h0000_0000);
         @cb;

         //Update the clock source before enabling the module to avoid clock glitches
         front_door_write_sfr(0, {21'b0,clk_src,8'b0});
         @cb;

         //Update the module SFRs
         front_door_write_sfr(1, tmr_val_value );
         front_door_write_sfr(2, tmr_mval0_value);
         front_door_write_sfr(3, tmr_mval1_value);
         front_door_write_sfr(0, tmr_ctrl_value);
         
         //Run the scenario for approx. 10 match events
         if(clk_src > 5) clk_src = 0;
         repeat(10*(2**clk_src)*period) begin
            @cb;
            check_all(mod);
         end
         report_passrate();

      endtask : base_functionality_test_seq

      task clock_gating_test_seq(model_tmr_c mod);
         int unsigned num_of_clks = 6;

         //Disable the module
         front_door_write_sfr(0, 32'h0000_0000);
         @cb;

         //Reset
         tb_rst_n = 1'b0;
         repeat(2) @(negedge tb_clk);
         tb_rst_n = 1'b1;
         mod.hard_reset();
         mod.debug_wfm_signals();

         //Synchronize after reset
         @cb;

         for (bit [2:0] i = 0; i < num_of_clks; i++) begin
            //Update the clock source and reset timer
            front_door_write_sfr(0, {21'b0,i,8'b0});
            @cb;
            //TODO update this test sequence
            //Update TMR configuration
            front_door_write_sfr(1, 32'h0000_0000);
            front_door_write_sfr(2, 32'h0000_0008);
            front_door_write_sfr(3, 32'h0000_0003);
            front_door_write_sfr(0, (32'h00E0_0083 | {21'b0,i,8'b0}));

            //Wait until the first match
            repeat(5*(2**i)) @cb;

            //System enters low power mode
            cb_n.tb_clk_en <= 0;

            //Wait until the second match should have been occured
            repeat(4*(2**i)) begin
               @cb;
               check_all(mod);
            end

            //System exists low power mode
            cb_n.tb_clk_en <= 1;

            //Wait until the second match occurs and some time after
            repeat(16*(2**i)) begin
               @cb;
               check_all(mod);
            end

            //Use the backdoor access to reset the SFRs
            back_door_write_sfr(1, 32'h0000_0000);
            back_door_write_sfr(2, 32'h0000_0000);
            back_door_write_sfr(3, 32'h0000_0000);
            back_door_write_sfr(0, 32'h0000_0000);

         end
         report_passrate();
         
      endtask : clock_gating_test_seq

   endclass : tmr_std_tests_c 

   //Define a clocking block for the input signals
   // Clocking block
   clocking cb @(posedge tb_clk);
      default input  #5ns;
      default output #10ns;
      //Sample
      input dut_hw_up_tmr_ctrl;
      input dut_hw_up_tmr_val;
      input dut_hw_up_tmr_mval0;
      input dut_hw_up_tmr_mval1;
      input dut_hw_val_tmr_ctrl;
      input dut_hw_val_tmr_val;
      input dut_hw_val_tmr_mval0;
      input dut_hw_val_tmr_mval1;
      input dut_match0_event;
      input dut_match1_event;
      input dut_ovf_event;
      //Drive -> for the sfr that control the TMR module
      output tb_addr;
      output tb_wen;
      output tb_wr_data_bus;
   endclocking
   //Clocking block for clock gate signal drive
   clocking cb_n @(negedge tb_clk);
      //Drive
      output tb_clk_en;
   endclocking

   //           |   __|____         _______
   //tb_clk ____|__/  |    \_______/       \______
   //           |     |      
   //           ^  ^  ^
   //           |  |  L> check that model & dut outputs match
   //           |  L> calculate the outputs for the model & dut
   //           L> drive inputs for the dut 

   //System Clock Generator Thread
   initial begin
      tb_clk      <=  0;
      forever #500ns tb_clk = !tb_clk;
   end

   //Divided Clocks Generator Thread
   always @(posedge tb_clk) tb_clk_div <= tb_clk_div + 1;

   //Testbench clock is selected by the clksrc bits in the tmr_ctrl_sfr
   always @(*) begin
      case (tmr_ctrl_sfr_out.clksrc)
         3'b000:  tb_dut_clk <= tb_clk;
         3'b001:  tb_dut_clk <= tb_clk_div[0];
         3'b010:  tb_dut_clk <= tb_clk_div[1];
         3'b011:  tb_dut_clk <= tb_clk_div[2];
         3'b100:  tb_dut_clk <= tb_clk_div[3];
         //TODO implement a random DCO clk 3'b101:  tb_dut_clk <= 0;
         default: tb_dut_clk <= tb_clk;
      endcase
   end

   always @(negedge tb_dut_clk) begin
      enable_model_clk <= tb_clk_en && tmr_ctrl_sfr_out.on;
   end
   assign tb_model_clk = tb_dut_clk & enable_model_clk;

   //Declare the model in the global space
   model_tmr_c model = new();
   //Verification model update logic
   initial begin
      fork
         begin
            forever begin
               @(posedge tb_model_clk);
               model.update_clk_posedge();
            end
         end
         begin
            forever begin
               @(posedge tb_dut_clk);
               #1ns;
               model.update_combo_logic();
            end
         end
         begin
            forever begin
               @(posedge tb_clk);
               #1ns;
               model.update_sfr_field_values();
               model.update_match_event_outputs();
            end
         end
      join
   end

   //Run the tests
   initial begin
      tmr_std_tests_c test_sequence = new();

      //Tie the clock enable and reset for the DUT to 1
      tb_rst_n       <= 1'b1;
      cb_n.tb_clk_en <= 1'b1;

      @(posedge tb_clk);

      $display("//+--------------------------------------------------------------+//");
      $display("//|                       Reset Test Start                       |//");
      $display("//+--------------------------------------------------------------+//");
      test_sequence.reset_test_seq(model);

      $display("//+--------------------------------------------------------------+//");
      $display("//|                 Functionality Tests Start                    |//");
      $display("//+--------------------------------------------------------------+//");
      //TODO update these test cases to match the timer behavior
      //Test 1 
      //Basic test for timer
      test_sequence.base_functionality_test_seq(
         32'h00E0_0081, //Events enabled, clksrc=sys, start, on
         32'h0000_0000, //TMR = 0
         32'h0000_0004, //MCH0 = 4
         32'h0000_0003, //MCH1 = 3
         model
         );

      //Test 2

      $display("//+--------------------------------------------------------------+//");
      $display("//|                   Clock Gating Test Start                    |//");
      $display("//+--------------------------------------------------------------+//");
      test_sequence.clock_gating_test_seq(model);

      $display("Stopping simulation.");
      $finish;
   end

endmodule : timer_nbit_v1_tb