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

   //TODO renunta la abordarea cu clase si fa golden model (mai rapid)
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
      bit                  pwm_out,    q_pwm_out;
      //Model Internal logic
      bit                  clk_en,     q_clk_en;
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
      function void update_clk_posedge();
         q_pr_ev      = pr_ev;
         q_dc_ev      = dc_ev;
         q_ph_ev      = ph_ev;
         q_of_ev      = of_ev;
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

      function void update_clk_negedge();
         q_clk_en     = clk_en;
      endfunction : update_clk_negedge

      function void update_clk_gate();
         this.clk_en = tb_clk_en;
      endfunction : update_clk_gate

      function void update_timer();
         if(pwm_ctrl_sfr_out.on && tb_rst_n && q_clk_en) begin
            if(q_rst_bit | pr_mch) 
               tmr = '0;
            else if(q_ld_bit) 
               tmr = pwm_tmr_sfr_out.tval;
            else
               tmr = q_tmr + 1;
         end
      endfunction : update_timer

      function void update_match_event_outputs();
         pr_mch = (tmr === pr_val);
         dc_mch = (tmr === dc_val);
         ph_mch = (tmr === ph_val);
         of_mch = (tmr === of_val);
         if(pwm_ctrl_sfr_out.on && tb_rst_n && q_clk_en) begin
            pr_ev = pr_mch && pwm_ctrl_sfr_out.prm_en;
            dc_ev = dc_mch && pwm_ctrl_sfr_out.dcm_en;
            ph_ev = ph_mch && pwm_ctrl_sfr_out.phm_en;
            of_ev = of_mch && pwm_ctrl_sfr_out.ofm_en;
         end
      endfunction : update_match_event_outputs

      function void update_pwm_out();
         bit pwm_val;

         pwm_val = q_pwm_out; //Retain the old value if no change is needed
         if(pwm_ctrl_sfr_out.on && tb_rst_n && q_clk_en) begin
            //Compute the new pwm output value
            if(q_rst_bit | (tmr === q_dc_val) | (q_dc_val <= q_ph_val))
               pwm_val = 0;
            else if(tmr == q_ph_val)
               pwm_val = 1;
         end
         //assign the output of the model the value from last step
         pwm_out = (pwm_val ^ pwm_ctrl_sfr_out.pol) & pwm_ctrl_sfr_out.oen;
      endfunction : update_pwm_out

      function void update_sfr_field_values();
        rst_bit    = pwm_ctrl_sfr_out.rst;
        ld_bit     = pwm_ctrl_sfr_out.ld;
        ld_trg_bit = pwm_ctrl_sfr_out.ld_trg;
         if(q_clk_en & pwm_ctrl_sfr_out.on) begin
            if(pwm_ctrl_sfr_out.ld_trg & pr_mch) begin
               pr_val = pwm_cfg0_sfr_out.pr;
               dc_val = pwm_cfg0_sfr_out.dc;
               ph_val = pwm_cfg1_sfr_out.ph;
               of_val = pwm_cfg1_sfr_out.of;
            end
         end
      endfunction : update_sfr_field_values

      function void update_hw_up_out();
         hw_up_pwm_ctrl = {
            of_mch, ph_mch, dc_mch, pr_mch, 4'b0,
            8'b0,
            8'b0,
            3'b0, (ld_trg_bit & q_pr_mch), pwm_ctrl_sfr_out.rd, q_ld_bit, q_rst_bit, 1'b0
         };
         hw_up_pwm_tmr  = {16'b0,{16{pwm_ctrl_sfr_out.rd}}};
         hw_up_pwm_cfg0 = '0;
         hw_up_pwm_cfg1 = '0;
      endfunction : update_hw_up_out
      
      function void update_hw_val_out();
         hw_val_pwm_ctrl = 32'hF000_0000;
         hw_val_pwm_tmr  = {16'b0,tmr};
         hw_val_pwm_cfg0 = '0;
         hw_val_pwm_cfg1 = '0;
      endfunction : update_hw_val_out

      function void update_combo_logic();
         update_sfr_field_values();
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
         dbg_clk_en           = clk_en;
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
         dbg_q_clk_en         = q_clk_en;
      endfunction : debug_wfm_signals

   endclass : model_pwm_c

   class pwm_tests_c;
      
      

   endclass : pwm_tests_c 

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

   //Verification model update logic
   initial begin
      model_pwm_c model = new();
      forever begin
         @(posedge tb_dut_clk);
         model.update_clk_posedge();
         #1ns;
         model.update_combo_logic();
         @(negedge tb_dut_clk);
         model.update_clk_negedge();
         #1ns;
         model.update_clk_gate();
      end
   end

   //Run the tests
   initial begin

      //Tie the clock enable and reset for the DUT to 1
      tb_rst_n       <= 1'b1;
      cb_n.tb_clk_en <= 1'b1;

      @(posedge tb_clk);
      tb_rst_n = 1'b0;
      repeat(2) @(negedge tb_clk);
      tb_rst_n = 1'b1;

      @cb;

      front_door_write_sfr(2, 32'h0004_0008);
      front_door_write_sfr(3, 32'h0005_0001);
      front_door_write_sfr(0, 32'h0F00_0141);
      front_door_write_sfr(0, 32'h0F00_0151);

      #100us;
      $display("Stopping simulation.");
      $finish;
   end

endmodule : pwm_nbit_v1_tb