//######################################## Header ########################################
//# Author: Vlad Rosu                                                                    #
//# Description: Tesetbench for the pulse width modulation generator module              #
//########################################################################################

module pwm_nbit_v1_tb#(
   parameter DATA_WIDTH = 32,
   parameter N = 16
) ();

   //Packages and libraries
   import pkg_verification_utils::*;
   import pkg_sfrs_definition::*;

   //Instantiate the real SFRs of the module
   sfr_module_v1 #(
      .SFR_ADDR_WIDTH(32),
      .SFR_WIDTH(32),
      .SFR_ADDRESS(0),
      .IMPLEMENTED_BITS_MASK(32'hFF0007DF),
      .READABLE_BITS_MASK(32'hFF0007C1),
      .SW_UPDATABLE_BITS_MASK(32'hFF0007DF),
      .HW_UPDATABLE_BITS_MASK(32'hF000001E)
   ) pwm_ctrl_sfr(
      //    Input ports
      .sys_clk          ( tb_clk              ),
      .sys_clk_en       ( tb_clk_en           ),
      .sys_rst_n        ( tb_rst_n            ),
      .sys_addr         ( tb_addr             ),
      .sys_wr_en        ( tb_wen              ),
      .sfr_hw_upate     ( dut_hw_up_pwm_ctrl  ),
      .sfr_hw_value     ( dut_hw_val_pwm_ctrl ),
      .sfr_sw_value     ( tb_wr_data_bus      ),
      //    Output ports
      .sfr_dout         ( pwm_ctrl_sfr_out    ),
      .sfr_rdonly_dout  (                     )
   );

   sfr_module_v1 #(
      .SFR_ADDR_WIDTH(32),
      .SFR_WIDTH(32),
      .SFR_ADDRESS(1),
      .IMPLEMENTED_BITS_MASK(32'h0000FFFF),
      .READABLE_BITS_MASK(32'h0000FFFF),
      .SW_UPDATABLE_BITS_MASK(32'h0000FFFF),
      .HW_UPDATABLE_BITS_MASK(32'h0000FFFF)
   ) pwm_tmr_sfr(
      //    Input ports
      .sys_clk          ( tb_clk              ),
      .sys_clk_en       ( tb_clk_en           ),
      .sys_rst_n        ( tb_rst_n            ),
      .sys_addr         ( tb_addr             ),
      .sys_wr_en        ( tb_wen              ),
      .sfr_hw_upate     ( dut_hw_up_pwm_tmr   ),
      .sfr_hw_value     ( dut_hw_val_pwm_tmr  ),
      .sfr_sw_value     ( tb_wr_data_bus      ),
      //    Output ports
      .sfr_dout         ( pwm_tmr_sfr_out     ),
      .sfr_rdonly_dout  (                     )
   );

   sfr_module_v1 #(
      .SFR_ADDR_WIDTH(32),
      .SFR_WIDTH(32),
      .SFR_ADDRESS(2),
      .IMPLEMENTED_BITS_MASK(32'hFFFFFFFF),
      .READABLE_BITS_MASK(32'hFFFFFFFF),
      .SW_UPDATABLE_BITS_MASK(32'hFFFFFFFF),
      .HW_UPDATABLE_BITS_MASK(32'h00000000)
   ) pwm_cfg0_sfr(
      //    Input ports
      .sys_clk          ( tb_clk              ),
      .sys_clk_en       ( tb_clk_en           ),
      .sys_rst_n        ( tb_rst_n            ),
      .sys_addr         ( tb_addr             ),
      .sys_wr_en        ( tb_wen              ),
      .sfr_hw_upate     ( dut_hw_up_pwm_cfg0  ),
      .sfr_hw_value     ( dut_hw_val_pwm_cfg0 ),
      .sfr_sw_value     ( tb_wr_data_bus      ),
      //    Output ports
      .sfr_dout         ( pwm_cfg0_sfr_out    ),
      .sfr_rdonly_dout  (                     )
   );

   sfr_module_v1 #(
      .SFR_ADDR_WIDTH(32),
      .SFR_WIDTH(32),
      .SFR_ADDRESS(3),
      .IMPLEMENTED_BITS_MASK(32'hFFFFFFFF),
      .READABLE_BITS_MASK(32'hFFFFFFFF),
      .SW_UPDATABLE_BITS_MASK(32'hFFFFFFFF),
      .HW_UPDATABLE_BITS_MASK(32'h00000000)
   ) pwm_cfg1_sfr(
      //    Input ports
      .sys_clk          ( tb_clk              ),
      .sys_clk_en       ( tb_clk_en           ),
      .sys_rst_n        ( tb_rst_n            ),
      .sys_addr         ( tb_addr             ),
      .sys_wr_en        ( tb_wen              ),
      .sfr_hw_upate     ( dut_hw_up_pwm_cfg1  ),
      .sfr_hw_value     ( dut_hw_val_pwm_cfg1 ),
      .sfr_sw_value     ( tb_wr_data_bus      ),
      //    Output ports
      .sfr_dout         ( pwm_cfg1_sfr_out    ),
      .sfr_rdonly_dout  (                     )
   );
   
   //Instantiate the DUT
   pwm_nbit_v1 #(
      .DATA_WIDTH(DATA_WIDTH),
      .N(N)
   ) dut(
      //    Input ports definition
      .sys_clk          ( tb_dut_clk          ),
      .sys_clk_en       ( tb_clk_en           ),
      .sys_rst_n        ( tb_rst_n            ),
      .pwm_ctrl         ( pwm_ctrl_sfr_out    ),
      .pwm_tmr          ( pwm_tmr_sfr_out     ),
      .pwm_cfg0         ( pwm_cfg0_sfr_out    ),
      .pwm_cfg1         ( pwm_cfg1_sfr_out    ),
      //    Output ports definition
      .hw_up_pwm_ctrl   ( dut_hw_up_pwm_ctrl  ),
      .hw_up_pwm_tmr    ( dut_hw_up_pwm_tmr   ),
      .hw_up_pwm_cfg0   ( dut_hw_up_pwm_cfg0  ),
      .hw_up_pwm_cfg1   ( dut_hw_up_pwm_cfg1  ),
      .hw_val_pwm_ctrl  ( dut_hw_val_pwm_ctrl ),
      .hw_val_pwm_tmr   ( dut_hw_val_pwm_tmr  ),
      .hw_val_pwm_cfg0  ( dut_hw_val_pwm_cfg0 ),
      .hw_val_pwm_cfg1  ( dut_hw_val_pwm_cfg1 ),
      .pr_match_event   ( dut_pr_match_event  ),
      .dc_match_event   ( dut_dc_match_event  ),
      .ph_match_event   ( dut_ph_match_event  ),
      .of_match_event   ( dut_of_match_event  ),
      .pwm_out          ( dut_pwm_out         )
);
   
   //DUT inputs
   bit                     tb_dut_clk;
   bit                     tb_clk_en;
   bit                     tb_rst_n;
   //These signals comes from the actual implemented SFR modules
   pwm_ctrl_t              pwm_ctrl_sfr_out;
   pwm_tmr_t               pwm_tmr_sfr_out;
   pwm_cfg0_t              pwm_cfg0_sfr_out;
   pwm_cfg1_t              pwm_cfg1_sfr_out;

   
   //DUT outputs (used logic for outputs because logic is 4-state type)
   logic [DATA_WIDTH-1:0]  dut_hw_up_pwm_ctrl;
   logic [DATA_WIDTH-1:0]  dut_hw_up_pwm_tmr;
   logic [DATA_WIDTH-1:0]  dut_hw_up_pwm_cfg0;
   logic [DATA_WIDTH-1:0]  dut_hw_up_pwm_cfg1;
   logic [DATA_WIDTH-1:0]  dut_hw_val_pwm_ctrl;
   logic [DATA_WIDTH-1:0]  dut_hw_val_pwm_tmr;
   logic [DATA_WIDTH-1:0]  dut_hw_val_pwm_cfg0;
   logic [DATA_WIDTH-1:0]  dut_hw_val_pwm_cfg1;
   logic                   dut_pr_match_event;
   logic                   dut_dc_match_event;
   logic                   dut_ph_match_event;
   logic                   dut_of_match_event;
   logic                   dut_pwm_out;

   //For debug waveform
   logic [DATA_WIDTH-1:0]  dbg_hw_up_pwm_ctrl;
   logic [DATA_WIDTH-1:0]  dbg_hw_up_pwm_tmr;
   logic [DATA_WIDTH-1:0]  dbg_hw_up_pwm_cfg0;
   logic [DATA_WIDTH-1:0]  dbg_hw_up_pwm_cfg1;
   logic [DATA_WIDTH-1:0]  dbg_hw_val_pwm_ctrl;
   logic [DATA_WIDTH-1:0]  dbg_hw_val_pwm_tmr;
   logic [DATA_WIDTH-1:0]  dbg_hw_val_pwm_cfg0;
   logic [DATA_WIDTH-1:0]  dbg_hw_val_pwm_cfg1;
   logic                   dbg_pr_ev;
   logic                   dbg_dc_ev;
   logic                   dbg_ph_ev;
   logic                   dbg_of_ev;
   logic                   dbg_pwm_out;
   logic                   dbg_pwm_out_port;
   logic                   dbg_clk_en;
   logic                   dbg_rst_bit;
   logic                   dbg_ld_bit;
   logic                   dbg_ld_trg_bit;
   logic          [N-1:0]  dbg_pr_val;
   logic          [N-1:0]  dbg_dc_val;
   logic          [N-1:0]  dbg_ph_val;
   logic          [N-1:0]  dbg_of_val;
   logic          [N-1:0]  dbg_tmr;
   logic                   dbg_pr_mch;
   logic                   dbg_dc_mch;
   logic                   dbg_ph_mch;
   logic                   dbg_of_mch;
   logic                   dbg_q_pr_ev;
   logic                   dbg_q_dc_ev;
   logic                   dbg_q_ph_ev;
   logic                   dbg_q_of_ev;
   logic                   dbg_q_pwm_out;
   logic                   dbg_q_rst_bit;
   logic                   dbg_q_ld_bit;
   logic                   dbg_q_ld_trg_bit;
   logic          [N-1:0]  dbg_q_pr_val;
   logic          [N-1:0]  dbg_q_dc_val;
   logic          [N-1:0]  dbg_q_ph_val;
   logic          [N-1:0]  dbg_q_of_val;
   logic          [N-1:0]  dbg_q_tmr;
   logic                   dbg_q_pr_mch;
   logic                   dbg_q_dc_mch;
   logic                   dbg_q_ph_mch;
   logic                   dbg_q_of_mch;
   logic                   dbg_q_clk_en;

   //TB utilities
   int unsigned            errors = 0;
   int unsigned            test_count = 0;
   bit                     tb_clk;
   bit              [3:0]  tb_clk_div;
   bit                     tb_model_clk;
   bit                     enable_model_clk;
   bit             [31:0]  tb_addr;
   bit                     tb_wen;
   bit   [DATA_WIDTH-1:0]  tb_wr_data_bus;


   task front_door_write_sfr(bit [31:0] addr, bit [DATA_WIDTH-1:0] data);
      cb.tb_addr        <= addr; //Put address on the addr bus
      cb.tb_wr_data_bus <= data; //Put data on the data bus
      cb.tb_wen         <= 1'b1; //Assert wen
      @cb;                       //Wait for the posedge to sample the data in the SFRs
      cb.tb_wen         <= 1'b0; //Deassert wen
      @cb;
   endtask : front_door_write_sfr

   //This function should be used carefully because it does not take into account the implemented bits masks
   task back_door_write_sfr(bit [31:0] addr, bit [DATA_WIDTH-1:0] data);
      //Force value into the SFR
      case (addr)
         0: force pwm_ctrl_sfr.sfr_value_ff = data;
         1: force pwm_tmr_sfr.sfr_value_ff  = data;
         2: force pwm_cfg0_sfr.sfr_value_ff = data;
         3: force pwm_cfg1_sfr.sfr_value_ff = data;
         default : $fatal("SFR with address = %0h does not exists!!!",addr);
      endcase
      //Immediately release the nets to not affect future logic that may update them
      release pwm_ctrl_sfr.sfr_value_ff;
      release pwm_tmr_sfr.sfr_value_ff;
      release pwm_cfg0_sfr.sfr_value_ff;
      release pwm_cfg1_sfr.sfr_value_ff;
   endtask : back_door_write_sfr

   class model_pwm_c;
      //Class Properties
      //IP outputs
      bit [DATA_WIDTH-1:0] hw_up_pwm_ctrl;
      bit [DATA_WIDTH-1:0] hw_up_pwm_tmr;
      bit [DATA_WIDTH-1:0] hw_up_pwm_cfg0;
      bit [DATA_WIDTH-1:0] hw_up_pwm_cfg1;
      bit [DATA_WIDTH-1:0] hw_val_pwm_ctrl;
      bit [DATA_WIDTH-1:0] hw_val_pwm_tmr;
      bit [DATA_WIDTH-1:0] hw_val_pwm_cfg0;
      bit [DATA_WIDTH-1:0] hw_val_pwm_cfg1;
      bit                  pr_ev,      q_pr_ev;
      bit                  dc_ev,      q_dc_ev;
      bit                  ph_ev,      q_ph_ev;
      bit                  of_ev,      q_of_ev;
      bit                  pwm_out,    q_pwm_out, pwm_out_port;
      //Model Internal logic
      bit                  rst_bit,    q_rst_bit;
      bit                  ld_bit,     q_ld_bit;
      bit                  ld_trg_bit, q_ld_trg_bit;
      bit          [N-1:0] pr_val,     q_pr_val;
      bit          [N-1:0] dc_val,     q_dc_val;
      bit          [N-1:0] ph_val,     q_ph_val;
      bit          [N-1:0] of_val,     q_of_val;
      bit          [N-1:0] tmr,        q_tmr;
      bit                  pr_mch,     q_pr_mch;
      bit                  dc_mch,     q_dc_mch;
      bit                  ph_mch,     q_ph_mch;
      bit                  of_mch,     q_of_mch;


      //Class Methods
      function void hard_reset();
         this.hw_up_pwm_ctrl    = 32'hF000_0000;
         this.hw_up_pwm_tmr     = '0;
         this.hw_up_pwm_cfg0    = '0;
         this.hw_up_pwm_cfg1    = '0;
         this.hw_val_pwm_ctrl   = 32'hF000_0000;
         this.hw_val_pwm_tmr    = '0;
         this.hw_val_pwm_cfg0   = '0;
         this.hw_val_pwm_cfg1   = '0;
         this.pr_ev             = '0;
         this.q_pr_ev           = '0;
         this.dc_ev             = '0;
         this.q_dc_ev           = '0;
         this.ph_ev             = '0;
         this.q_ph_ev           = '0;
         this.of_ev             = '0;
         this.q_of_ev           = '0;
         this.pwm_out           = '0;
         this.q_pwm_out         = '0;
         this.pwm_out_port      = '0;
         this.rst_bit           = '0;
         this.q_rst_bit         = '0;
         this.ld_bit            = '0;
         this.q_ld_bit          = '0;
         this.ld_trg_bit        = '0;
         this.q_ld_trg_bit      = '0;
         this.pr_val            = '0;
         this.q_pr_val          = '0;
         this.dc_val            = '0;
         this.q_dc_val          = '0;
         this.ph_val            = '0;
         this.q_ph_val          = '0;
         this.of_val            = '0;
         this.q_of_val          = '0;
         this.tmr               = '0;
         this.q_tmr             = '0;
         this.pr_mch            =  1;
         this.q_pr_mch          = '0;
         this.dc_mch            =  1;
         this.q_dc_mch          = '0;
         this.ph_mch            =  1;
         this.q_ph_mch          = '0;
         this.of_mch            =  1;
         this.q_of_mch          = '0;
      endfunction : hard_reset

      function void update_clk_posedge();
         q_pr_ev      = pr_mch;
         q_dc_ev      = dc_mch;
         q_ph_ev      = ph_mch;
         q_of_ev      = of_mch;
         q_pwm_out    = pwm_out;
         q_rst_bit    = rst_bit;
         q_ld_bit     = ld_bit;
         q_ld_trg_bit = ld_trg_bit;
         q_pr_val     = pr_val;
         q_dc_val     = dc_val;
         q_ph_val     = ph_val;
         q_of_val     = of_val;
         q_tmr        = tmr;
         q_pr_mch     = pr_mch;
         q_dc_mch     = dc_mch;
         q_ph_mch     = ph_mch;
         q_of_mch     = of_mch;
      endfunction : update_clk_posedge

      function void update_timer();
         if(tb_rst_n) begin
            if((rst_bit & q_rst_bit) | (q_tmr === q_pr_val)) 
               tmr = '0;
            else if(ld_bit) 
               tmr = pwm_tmr_sfr_out.tval;
            else
               tmr = q_tmr + 1;
         end
      endfunction : update_timer

      function void update_match_event_outputs();
         pr_mch = (q_tmr === q_pr_val) & pwm_ctrl_sfr_out.on;
         dc_mch = (q_tmr === q_dc_val) & pwm_ctrl_sfr_out.on;
         ph_mch = (q_tmr === q_ph_val) & pwm_ctrl_sfr_out.on;
         of_mch = (q_tmr === q_of_val) & pwm_ctrl_sfr_out.on;
         if(tb_rst_n) begin
            pr_ev = q_pr_ev && pwm_ctrl_sfr_out.prm_en;
            dc_ev = q_dc_ev && pwm_ctrl_sfr_out.dcm_en;
            ph_ev = q_ph_ev && pwm_ctrl_sfr_out.phm_en;
            of_ev = q_of_ev && pwm_ctrl_sfr_out.ofm_en;
         end
      endfunction : update_match_event_outputs
 
      function void update_pwm_out();
         bit pwm_val;

         if(tb_rst_n) begin
            //Compute the new pwm output value
            if((rst_bit & q_rst_bit) | dc_mch | (q_dc_val <= q_ph_val))
               pwm_val = 0;
            else if(ph_mch)
               pwm_val = 1;
            else
               pwm_val = q_pwm_out; //Pass the old value if no change is needed
         end
         //assign the output of the model the value from last step
         pwm_out = pwm_val;
         update_pwm_out_port();
      endfunction : update_pwm_out

      function void update_pwm_out_port();
         pwm_out_port = (q_pwm_out ^ pwm_ctrl_sfr_out.pol) & pwm_ctrl_sfr_out.oen;
      endfunction : update_pwm_out_port

      function void update_sfr_field_values();
         rst_bit    = pwm_ctrl_sfr_out.rst;
         ld_bit     = pwm_ctrl_sfr_out.ld;
         ld_trg_bit = pwm_ctrl_sfr_out.ld_trg;
      endfunction : update_sfr_field_values

      function void update_shadow_buffers();
         if(pwm_ctrl_sfr_out.ld_trg & (q_tmr === q_pr_val)) begin
            pr_val = pwm_cfg0_sfr_out.pr;
            dc_val = pwm_cfg0_sfr_out.dc;
            ph_val = pwm_cfg1_sfr_out.ph;
            of_val = pwm_cfg1_sfr_out.of;
         end
      endfunction : update_shadow_buffers

      function void update_hw_up_out();
         hw_up_pwm_ctrl = {
            of_mch, ph_mch, dc_mch, pr_mch, 4'b0,
            8'b0,
            8'b0,
            3'b0, (q_ld_trg_bit & q_pr_mch), pwm_ctrl_sfr_out.rd, q_ld_bit, (rst_bit & q_rst_bit), 1'b0
         };
         hw_up_pwm_tmr  = {16'b0,{16{pwm_ctrl_sfr_out.rd}}};
         hw_up_pwm_cfg0 = '0;
         hw_up_pwm_cfg1 = '0;
      endfunction : update_hw_up_out
      
      function void update_hw_val_out();
         hw_val_pwm_ctrl = 32'hF000_0000;
         hw_val_pwm_tmr  = {16'b0,q_tmr};
         hw_val_pwm_cfg0 = '0;
         hw_val_pwm_cfg1 = '0;
      endfunction : update_hw_val_out

      function void update_combo_logic();
         update_sfr_field_values();
         update_shadow_buffers();
         update_timer();
         update_match_event_outputs();
         update_pwm_out();
         update_hw_val_out();
         update_hw_up_out();
         
         debug_wfm_signals();
      endfunction : update_combo_logic

      function void debug_wfm_signals();
         dbg_hw_up_pwm_ctrl   = hw_up_pwm_ctrl;
         dbg_hw_up_pwm_tmr    = hw_up_pwm_tmr;
         dbg_hw_up_pwm_cfg0   = hw_up_pwm_cfg0;
         dbg_hw_up_pwm_cfg1   = hw_up_pwm_cfg1;
         dbg_hw_val_pwm_ctrl  = hw_val_pwm_ctrl;
         dbg_hw_val_pwm_tmr   = hw_val_pwm_tmr;
         dbg_hw_val_pwm_cfg0  = hw_val_pwm_cfg0;
         dbg_hw_val_pwm_cfg1  = hw_val_pwm_cfg1;
         dbg_pr_ev            = pr_ev;
         dbg_dc_ev            = dc_ev;
         dbg_ph_ev            = ph_ev;
         dbg_of_ev            = of_ev;
         dbg_pwm_out          = pwm_out;
         dbg_pwm_out_port     = pwm_out_port;
         dbg_rst_bit          = rst_bit;
         dbg_ld_bit           = ld_bit;
         dbg_ld_trg_bit       = ld_trg_bit;
         dbg_pr_val           = pr_val;
         dbg_dc_val           = dc_val;
         dbg_ph_val           = ph_val;
         dbg_of_val           = of_val;
         dbg_tmr              = tmr;
         dbg_pr_mch           = pr_mch;
         dbg_dc_mch           = dc_mch;
         dbg_ph_mch           = ph_mch;
         dbg_of_mch           = of_mch;
         dbg_q_pr_ev          = q_pr_ev;
         dbg_q_dc_ev          = q_dc_ev;
         dbg_q_ph_ev          = q_ph_ev;
         dbg_q_of_ev          = q_of_ev;
         dbg_q_pwm_out        = q_pwm_out;
         dbg_q_rst_bit        = q_rst_bit;
         dbg_q_ld_bit         = q_ld_bit;
         dbg_q_ld_trg_bit     = q_ld_trg_bit;
         dbg_q_pr_val         = q_pr_val;
         dbg_q_dc_val         = q_dc_val;
         dbg_q_ph_val         = q_ph_val;
         dbg_q_of_val         = q_of_val;
         dbg_q_tmr            = q_tmr;
         dbg_q_pr_mch         = q_pr_mch;
         dbg_q_dc_mch         = q_dc_mch;
         dbg_q_ph_mch         = q_ph_mch;
         dbg_q_of_mch         = q_of_mch;
      endfunction : debug_wfm_signals

   endclass : model_pwm_c

   class pwm_std_tests_c;

      function void check_outputs(logic[DATA_WIDTH-1:0] dut_out, logic[DATA_WIDTH-1:0] expected, string sig_name);
         if(dut_out !== expected) begin
            errors++;
            $display("ERROR on %s!!! -> Time %0t: expected=%0h, dut_out=%0h",sig_name, $time(), expected, dut_out);
         end

         test_count++; //increment test_count for each test
      endfunction : check_outputs

      function void check_all(model_pwm_c mod);
         check_outputs(dut_pwm_out, mod.pwm_out_port, "pwm_out");
         check_outputs({dut_of_match_event, dut_ph_match_event, dut_dc_match_event, dut_pr_match_event}, 
                       {mod.of_ev, mod.ph_ev, mod.dc_ev, mod.pr_ev}, "events outputs");
         check_outputs(dut_hw_up_pwm_ctrl, mod.hw_up_pwm_ctrl, "hw_up_pwm_ctrl");
         check_outputs(dut_hw_up_pwm_tmr,  mod.hw_up_pwm_tmr,  "hw_up_pwm_tmr");
         check_outputs(dut_hw_up_pwm_cfg0, mod.hw_up_pwm_cfg0, "hw_up_pwm_cfg0");
         check_outputs(dut_hw_up_pwm_cfg1, mod.hw_up_pwm_cfg1, "hw_up_pwm_cfg1");
         check_outputs(dut_hw_val_pwm_ctrl, mod.hw_val_pwm_ctrl, "hw_val_pwm_ctrl");
         check_outputs(dut_hw_val_pwm_tmr,  mod.hw_val_pwm_tmr,  "hw_val_pwm_tmr");
         check_outputs(dut_hw_val_pwm_cfg0, mod.hw_val_pwm_cfg0, "hw_val_pwm_cfg0");
         check_outputs(dut_hw_val_pwm_cfg1, mod.hw_val_pwm_cfg1, "hw_val_pwm_cfg1");
      endfunction : check_all

      function void report_passrate();
         $display("Pass Rate: %3.2f%%",((test_count-errors)/real'(test_count))*100);
         //After each report clear the number of tests and errors
         test_count = 0;
         errors = 0;
      endfunction : report_passrate
      
      task reset_test_seq(model_pwm_c mod);
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
         bit [DATA_WIDTH-1:0]    pwm_ctrl_value,
         bit [DATA_WIDTH-1:0]    pwm_tmr_value,
         bit [DATA_WIDTH-1:0]    pwm_cfg0_value,
         bit [DATA_WIDTH-1:0]    pwm_cfg1_value,
         model_pwm_c             mod
         );
         logic [2:0] clk_src;
         int unsigned period;

         clk_src = pwm_ctrl_value[10:8];
         period = pwm_cfg0_value[15:0];

         //Disable the module
         front_door_write_sfr(0, 32'h0000_0000);
         @cb;

         //Update the clock source before enabling the module to avoid clock glitches
         front_door_write_sfr(0, {21'b0,clk_src,8'b0});
         @cb;

         //Update the module SFRs
         front_door_write_sfr(1, pwm_tmr_value);
         front_door_write_sfr(2, pwm_cfg0_value);
         front_door_write_sfr(3, pwm_cfg1_value);
         front_door_write_sfr(0, pwm_ctrl_value);
         
         //Run the scenario for approx. 10 PWM periods
         if(clk_src > 4) clk_src = 0;
         repeat(10*(2**clk_src)*period) begin
            @cb;
            check_all(mod);
         end
         report_passrate();

      endtask : base_functionality_test_seq

      task clock_gating_test_seq(model_pwm_c mod);
         int unsigned num_of_clks = 5;

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

            //Update PWM configuration
            front_door_write_sfr(1, 32'h0000_0000);
            front_door_write_sfr(2, 32'h0003_0006);
            front_door_write_sfr(3, 32'h0001_0000);
            front_door_write_sfr(0, (32'h0F00_0055 | {21'b0,i,8'b0}));

            //Wait 2 PWM periods
            repeat(2*6*(2**i)) @cb;

            //System enters low power mode
            cb_n.tb_clk_en <= 0;

            //Wait 2 PWM periods and check
            repeat(2*6*(2**i)) begin
               @cb;
               check_all(mod);
            end

            //System exists low power mode
            cb_n.tb_clk_en <= 1;

            //Wait 2 PWM periods and check
            repeat(2*6*(2**i)) begin
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

   endclass : pwm_std_tests_c 

   //Define a clocking block for the input signals
   // Clocking block
   clocking cb @(posedge tb_clk);
      default input  #5ns;
      default output #10ns;
      //Sample
      input dut_hw_up_pwm_ctrl;
      input dut_hw_up_pwm_tmr;
      input dut_hw_up_pwm_cfg0;
      input dut_hw_up_pwm_cfg1;
      input dut_hw_val_pwm_ctrl;
      input dut_hw_val_pwm_tmr;
      input dut_hw_val_pwm_cfg0;
      input dut_hw_val_pwm_cfg1;
      input dut_pr_match_event;
      input dut_dc_match_event;
      input dut_ph_match_event;
      input dut_of_match_event;
      input dut_pwm_out;
      //Drive -> for the sfr that control the PWM module
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

   //Testbench clock is selected by the clksrc bits in the pwm_ctrl_sfr
   always @(*) begin
      case (pwm_ctrl_sfr_out.clksrc)
         3'b000:  tb_dut_clk <= tb_clk;
         3'b001:  tb_dut_clk <= tb_clk_div[0];
         3'b010:  tb_dut_clk <= tb_clk_div[1];
         3'b011:  tb_dut_clk <= tb_clk_div[2];
         3'b100:  tb_dut_clk <= tb_clk_div[3];
         default: tb_dut_clk <= tb_clk;
      endcase
   end

   always @(negedge tb_dut_clk) begin
      enable_model_clk <= tb_clk_en && pwm_ctrl_sfr_out.on;
   end
   assign tb_model_clk = tb_dut_clk & enable_model_clk;

   //Declare the model in the global space
   model_pwm_c model = new();
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
               model.update_pwm_out_port();
            end
         end
      join
   end

   //Run the tests
   initial begin
      pwm_std_tests_c test_sequence = new();

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
      
      //Test 1 
      //Test shadow buffers load, standard PWM output and standard PWM events
      test_sequence.base_functionality_test_seq(
         32'h0F00_0051, //Events enabled, clksrc=sys, oen, ld buff, on
         32'h0000_0000, //TMR = 0
         32'h0004_0008, //DC = 4, PR = 8
         32'h0005_0001, //OF = 5, PH = 1
         model
         );

      //Test 2
      //Test timer load and PWM duty cycle 50%
      test_sequence.base_functionality_test_seq(
         32'h0F00_0155, //Events enabled, clksrc=sys_div2, oen, ld tmr, ld buff, on
         32'h0000_FFFA, //TMR = MAX - 5
         32'h0005_000A, //DC = 5, PR = 10
         32'hFFFC_0000, //OF = FFFC, PH = 0
         model
         );

      //Test 3
      //Test register reset and no events enabled
      test_sequence.base_functionality_test_seq(
         32'h0000_0042, //clksrc=sys, oen, rst
         32'h0000_0005, //TMR = 5
         32'h0005_000A, //DC = 5, PR = 10
         32'h0000_0000, //OF = 0, PH = 0
         model
         );

      //Test 4
      //Test register read and inverted polarity
      test_sequence.base_functionality_test_seq(
         32'h0300_04D1, //PR,DC event enabled, clksrc=sys_div16, polarity inverted, oen, ld_trg, on
         32'h0000_0000, //TMR = 0
         32'h0001_0003, //DC = 1, PR = 3
         32'h0002_0000, //OF = 0, PH = 0
         model
         );

      //Test 5
      //Test corner case DC < PH, and invalid clock selection bits
      test_sequence.base_functionality_test_seq(
         32'h0F00_0751, //Events enabled, clksrc=invalid, oen, ld_trg, on
         32'h0000_0002, //TMR = 2
         32'h0004_0006, //DC = 4, PR = 6
         32'h0001_0002, //OF = 1, PH = 2
         model
         );

      //Test 6
      //Test corner case DC > PR
      test_sequence.base_functionality_test_seq(
         32'h0F00_0351, //Events enabled, clksrc=sys_div8, oen, ld_trg, on
         32'h0000_0000, //TMR = 0
         32'h000A_0008, //DC = 10, PR = 8
         32'h0009_0005, //OF = 1, PH = 5
         model
         );

      //Test 7
      //Test corner case PH > PR
      test_sequence.base_functionality_test_seq(
         32'h0F00_0051, //Events enabled, clksrc=sys, oen, ld_trg, on
         32'h0000_0000, //TMR = 0
         32'h0006_0007, //DC = 6, PR = 7
         32'h0000_0009, //OF = 0, PH = 9
         model
         );

      //Test 8
      //Test output disabled and read
      test_sequence.base_functionality_test_seq(
         32'h0F00_0111, //Events enabled, clksrc=sys_div2, oen, ld_trg, on
         32'h0000_0000, //TMR = 0
         32'h0006_0007, //DC = 4, PR = 6
         32'h0000_0009, //OF = 4, PH = 1
         model
         );

      $display("//+--------------------------------------------------------------+//");
      $display("//|                   Clock Gating Test Start                    |//");
      $display("//+--------------------------------------------------------------+//");
      test_sequence.clock_gating_test_seq(model);

      $display("Stopping simulation.");
      $finish;
   end

endmodule : pwm_nbit_v1_tb