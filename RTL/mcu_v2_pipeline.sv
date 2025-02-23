//######################################## Header ########################################
//# Author: Vlad Rosu                                                                    #
//# Description: Top file for the Pipeline MCU aka v2, containing all modules            #
//########################################################################################

module mcu_v2_pipeline #(
   parameter ADDR_BUS_WIDTH            = 32,
   parameter DATA_BUS_WIDTH            = 32,
   parameter CPU_REG_FILE_ADDR_WIDTH   = 5
)(
   //    Input ports definition
   input                         sys_clk,
   input                         sys_rst_n,
   //    Output ports definition
   output [DATA_BUS_WIDTH-1:0]   pfm_rd_instr,
   output [DATA_BUS_WIDTH-1:0]   dfm_rd_data,
   output [ADDR_BUS_WIDTH-1:0]   pfm_req_addr,
   output [ADDR_BUS_WIDTH-1:0]   cpu_req_addr,
   output                        cpu_wr_en,
   output [DATA_BUS_WIDTH-1:0]   cpu_wr_data,
   output [DATA_BUS_WIDTH-1:0]   sys_rd_bus
);

   //==========================
   // Packages and defines
   //==========================
   import pkg_sfrs_definition::*;

   //==========================
   // Local Parameters
   //==========================
   localparam logic [ADDR_BUS_WIDTH-1:0] CHIP_BASE_ADDR = 32'hFFFFF800;
   localparam logic [ADDR_BUS_WIDTH-1:0] TMR0_BASE_ADDR = 32'hFFFFF804;
   localparam logic [ADDR_BUS_WIDTH-1:0] TMR1_BASE_ADDR = 32'hFFFFF814;
   localparam logic [ADDR_BUS_WIDTH-1:0] PWM0_BASE_ADDR = 32'hFFFFF824;
   localparam logic [ADDR_BUS_WIDTH-1:0] PWM1_BASE_ADDR = 32'hFFFFF834;
   localparam logic [ADDR_BUS_WIDTH-1:0] PWM2_BASE_ADDR = 32'hFFFFF844;
   localparam logic [ADDR_BUS_WIDTH-1:0] DCO_BASE_ADDR  = 32'hFFFFF854;

   //==========================
   // Wire declarations
   //==========================
   //System level wires
   logic [DATA_BUS_WIDTH-1:0] io_rd_bus;
   logic [DATA_BUS_WIDTH-1:0] sfr_rd_bus;
   //logic [DATA_BUS_WIDTH-1:0] sys_rd_bus;
   //Chip Sfrs
   chip_ctrl_t                chip_ctrl_sfr_out;
   chip_ctrl_t                chip_ctrl_sfr_rd;
   logic                      chip_lp_mode;
   logic [DATA_BUS_WIDTH-1:0] chip_sfr_rd_bus;
   //CPU
   // logic [DATA_BUS_WIDTH-1:0] pfm_rd_instr;
   // logic [DATA_BUS_WIDTH-1:0] dfm_rd_data;
   // logic [ADDR_BUS_WIDTH-1:0] pfm_req_addr;
   // logic [ADDR_BUS_WIDTH-1:0] cpu_req_addr;
   // logic                      cpu_wr_en;
   // logic [DATA_BUS_WIDTH-1:0] cpu_wr_data;
   // Memory Map Decoder
   logic                      en_mem_sfr;
   logic                      en_mem_io;
   logic                      en_mem_undef;
   logic                      en_mem_dfm;
   logic                      en_mem_pfm;
   //Prescaller
   logic                [3:0] sys_clk_div;
   //TMR0
   logic [DATA_BUS_WIDTH-1:0] tmr0_sfr_rd_bus;
   logic                      tmr0_m0_if;
   logic                      tmr0_m1_if;
   logic                      tmr0_ovf_if;
   //TMR1
   logic [DATA_BUS_WIDTH-1:0] tmr1_sfr_rd_bus;
   logic                      tmr1_m0_if;
   logic                      tmr1_m1_if;
   logic                      tmr1_ovf_if;
   //PWM0
   logic [DATA_BUS_WIDTH-1:0] pwm0_sfr_rd_bus;
   logic                      pwm0_pr_if;
   logic                      pwm0_dc_if;
   logic                      pwm0_ph_if;
   logic                      pwm0_of_if;
   logic                      pwm0_out;
   //PWM1
   logic [DATA_BUS_WIDTH-1:0] pwm1_sfr_rd_bus;
   logic                      pwm1_pr_if;
   logic                      pwm1_dc_if;
   logic                      pwm1_ph_if;
   logic                      pwm1_of_if;
   logic                      pwm1_out;
   //PWM2
   logic [DATA_BUS_WIDTH-1:0] pwm2_sfr_rd_bus;
   logic                      pwm2_pr_if;
   logic                      pwm2_dc_if;
   logic                      pwm2_ph_if;
   logic                      pwm2_of_if;
   logic                      pwm2_out;
   //DCO
   logic [DATA_BUS_WIDTH-1:0] dco_sfr_rd_bus;
   logic                      dco_clk;
  
   //==========================
   // Flip-flop declarations
   //==========================


   //==========================
   // System SFRs
   //==========================
   sfr_module_v1 #(
      .SFR_ADDR_WIDTH(ADDR_BUS_WIDTH),
      .SFR_WIDTH(DATA_BUS_WIDTH),
      .SFR_ADDRESS(CHIP_BASE_ADDR),
      .IMPLEMENTED_BITS_MASK(32'h0000_0080),
      .READABLE_BITS_MASK(32'h0000_0080),
      .SW_UPDATABLE_BITS_MASK(32'h0000_0080),
      .HW_UPDATABLE_BITS_MASK(32'h0000_0000)
   ) chip_ctrl_sfr(
      //    Input ports
      .sys_clk          ( sys_clk            ),
      .sys_clk_en       ( 1'b1               ), //CHIP SFRs are always enabled
      .sys_rst_n        ( sys_rst_n          ),
      .sys_addr         ( cpu_req_addr       ),
      .sys_wr_en        ( sfr_wr_en          ),
      .sfr_hw_upate     ( '0                 ),
      .sfr_hw_value     ( '0                 ),
      .sfr_sw_value     ( cpu_wr_data        ),
      //    Output ports
      .sfr_dout         ( chip_ctrl_sfr_out  ),
      .sfr_rdonly_dout  ( chip_ctrl_sfr_rd   )
   );

   assign chip_lp_mode = ~chip_ctrl_sfr_out.lpm;
   assign chip_sfr_rd_bus = chip_ctrl_sfr_rd;

   //==========================
   // CPU Instance
   //==========================
   assign sys_rd_bus =  en_mem_dfm ? dfm_rd_data :
                        en_mem_io  ? io_rd_bus   :
                        en_mem_sfr ? sfr_rd_bus  :
                                     'x          ; //TODO for now propagate X but this might affect the synthesis based on the tool engine

   cpu_pipeline_v2 #(
      .ADDR_WIDTH(ADDR_BUS_WIDTH),
      .DATA_WIDTH(DATA_BUS_WIDTH),
      .REG_FILE_ADDR_WIDTH(CPU_REG_FILE_ADDR_WIDTH)
   ) cpu(
      //    Input ports definition
      .sys_clk       ( sys_clk                  ),
      .sys_rst_n     ( sys_rst_n                ),
      .pfm_rd_instr  ( pfm_rd_instr             ),
      .dfm_rd_data   ( sys_rd_bus               ),
      //    Output ports definition
      .pfm_req_addr  ( pfm_req_addr             ), //FIXME maybe can add HW protection for end of memory by wiring MSB bit of the pfm_req addr to the memory to 0
      .dfm_req_addr  ( cpu_req_addr             ),
      .dfm_wr_en     ( cpu_wr_en                ),
      .dfm_wr_data   ( cpu_wr_data              )
   );

   assign dfm_wr_en = cpu_wr_en & en_mem_dfm;
   assign sfr_wr_en = cpu_wr_en & en_mem_sfr;
   assign io_wr_en  = cpu_wr_en & en_mem_io;

   //==========================
   // Memory Map Decoder Instance
   //==========================
   mem_map_dec mem_map_dec(
      //    Input ports definition
      .sys_address   ( cpu_req_addr             ),
      //    Output ports definition
      .en_mem_sfr    ( en_mem_sfr               ),
      .en_mem_io     ( en_mem_io                ),
      .en_mem_undef  ( en_mem_undef             ),
      .en_mem_dfm    ( en_mem_dfm               ),
      .en_mem_pfm    ( en_mem_pfm               )
   );

   //TODO: For synthesis PFM needs a real ram implementation
   //==========================
   // PFM Instance
   //==========================
   nvm_mem #(
      .MEM_ADDR_WIDTH(ADDR_BUS_WIDTH-2), //TODO use ADDR_BUS_WIDTH-2 because the PFM only increments by 4?
      .MEM_DATA_WIDTH(DATA_BUS_WIDTH)
   ) pfm(
      //    Input ports
      .clk           ( sys_clk                  ),
      .we            ( 1'b0                     ), //TODO PFM should support write only on programming
      .addr          ( pfm_req_addr[31:2]       ), //TODO select only necessary bits (look in mem decoder)
      .wd            ( cpu_wr_data              ),
      //    Output ports
      .rd            ( pfm_rd_instr             )
   );

   //TODO: For synthesis DFM needs a real ram implementation
   //==========================
   // DFM Instance
   //==========================
   nvm_mem #(
      .MEM_ADDR_WIDTH(ADDR_BUS_WIDTH-6),
      .MEM_DATA_WIDTH(DATA_BUS_WIDTH)
   ) dfm(
      //    Input ports
      .clk           ( sys_clk                  ),
      .we            ( dfm_wr_en                ),
      .addr          ( cpu_req_addr[27:2]       ), //TODO select only necessary bits (look in mem decoder)
      .wd            ( cpu_wr_data              ),
      //    Output ports
      .rd            ( dfm_rd_data              )
   );

   //==========================
   // Prescaller Instance
   //==========================
   clk_prescaller_v1 #(
      .DIV_RESOLUTION(4)
   ) prescaller(
      //    Input ports definition
      .sys_clk       ( sys_clk                  ),
      .sys_clk_en    ( chip_lp_mode             ),
      .sys_rst_n     ( sys_rst_n                ),
      //    Output ports definition
      .pclk_out      ( sys_clk_div              )
   );

   //==========================
   // DCO Instance
   //==========================
   dco_20bit_v1 #(
      .DATA_WIDTH(DATA_BUS_WIDTH),
      .ADDR_WIDTH(ADDR_BUS_WIDTH),
      .BASE_ADDR(DCO_BASE_ADDR),
      .N(20)
   )  dco_20bit(
      //    Input ports definition
      .sys_clk       ( sys_clk                  ),
      .sys_clk_div   ( sys_clk_div              ),
      .sys_clk_en    ( chip_lp_mode             ),
      .sys_rst_n     ( sys_rst_n                ),
      .sys_addr      ( cpu_req_addr             ),
      .sys_wr_en     ( sfr_wr_en                ),
      .sys_sw_value  ( cpu_wr_data              ),
      //    Output ports definition
      .sfr_rd_dout   ( dco_sfr_rd_bus           ),
      .dco_clk_out   ( dco_clk                  )
   );

   //==========================
   // TMR0 Instance
   //==========================
   tmr_32bit_v1 #(
      .DATA_WIDTH(DATA_BUS_WIDTH),
      .ADDR_WIDTH(ADDR_BUS_WIDTH),
      .BASE_ADDR(TMR0_BASE_ADDR),
      .N(32)
   ) tmr0_32bit(
      //    Input ports definition
      .sys_clk       ( sys_clk                  ),
      .sys_clk_div   ( {dco_clk, sys_clk_div}   ),
      .sys_clk_en    ( chip_lp_mode             ),
      .sys_rst_n     ( sys_rst_n                ),
      .sys_addr      ( cpu_req_addr             ),
      .sys_wr_en     ( sfr_wr_en                ),
      .sys_sw_value  ( cpu_wr_data              ),
      //    Output ports definition
      .sfr_rd_dout   ( tmr0_sfr_rd_bus          ),
      .match0_event  ( tmr0_m0_if               ),
      .match1_event  ( tmr0_m1_if               ),
      .ovf_event     ( tmr0_ovf_if              )
   );

   //==========================
   // TMR1 Instance
   //==========================
   tmr_32bit_v1 #(
      .DATA_WIDTH(DATA_BUS_WIDTH),
      .ADDR_WIDTH(ADDR_BUS_WIDTH),
      .BASE_ADDR(TMR1_BASE_ADDR),
      .N(32)
   ) tmr1_32bit(
      //    Input ports definition
      .sys_clk       ( sys_clk                  ),
      .sys_clk_div   ( {dco_clk, sys_clk_div}   ),
      .sys_clk_en    ( chip_lp_mode             ),
      .sys_rst_n     ( sys_rst_n                ),
      .sys_addr      ( cpu_req_addr             ),
      .sys_wr_en     ( sfr_wr_en                ),
      .sys_sw_value  ( cpu_wr_data              ),
      //    Output ports definition
      .sfr_rd_dout   ( tmr1_sfr_rd_bus          ),
      .match0_event  ( tmr1_m0_if               ),
      .match1_event  ( tmr1_m1_if               ),
      .ovf_event     ( tmr1_ovf_if              )
   );

   //==========================
   // PWM0 Instance
   //==========================
   pwm_16bit_v1 #(
      .DATA_WIDTH(DATA_BUS_WIDTH),
      .ADDR_WIDTH(ADDR_BUS_WIDTH),
      .BASE_ADDR(PWM0_BASE_ADDR),
      .N(16)
   ) pwm0_16bit(
      //    Input ports definition
      .sys_clk       ( sys_clk                  ),
      .sys_clk_div   ( sys_clk_div              ),
      .sys_clk_en    ( chip_lp_mode             ),
      .sys_rst_n     ( sys_rst_n                ),
      .sys_addr      ( cpu_req_addr             ),
      .sys_wr_en     ( sfr_wr_en                ),
      .sys_sw_value  ( cpu_wr_data              ),
      //    Output ports definition
      .sfr_rd_dout   ( pwm0_sfr_rd_bus          ),
      .pr_event      ( pwm0_pr_if               ),
      .dc_event      ( pwm0_dc_if               ),
      .ph_event      ( pwm0_ph_if               ),
      .of_event      ( pwm0_of_if               ),
      .pwm_out       ( pwm0_out                 )
   );

   //==========================
   // PWM1 Instance
   //==========================
   pwm_16bit_v1 #(
      .DATA_WIDTH(DATA_BUS_WIDTH),
      .ADDR_WIDTH(ADDR_BUS_WIDTH),
      .BASE_ADDR(PWM1_BASE_ADDR),
      .N(16)
   ) pwm1_16bit(
      //    Input ports definition
      .sys_clk       ( sys_clk                  ),
      .sys_clk_div   ( sys_clk_div              ),
      .sys_clk_en    ( chip_lp_mode             ),
      .sys_rst_n     ( sys_rst_n                ),
      .sys_addr      ( cpu_req_addr             ),
      .sys_wr_en     ( sfr_wr_en                ),
      .sys_sw_value  ( cpu_wr_data              ),
      //    Output ports definition
      .sfr_rd_dout   ( pwm1_sfr_rd_bus          ),
      .pr_event      ( pwm1_pr_if               ),
      .dc_event      ( pwm1_dc_if               ),
      .ph_event      ( pwm1_ph_if               ),
      .of_event      ( pwm1_of_if               ),
      .pwm_out       ( pwm1_out                 )
   );

   //==========================
   // PWM2 Instance
   //==========================
   pwm_16bit_v1 #(
      .DATA_WIDTH(DATA_BUS_WIDTH),
      .ADDR_WIDTH(ADDR_BUS_WIDTH),
      .BASE_ADDR(PWM2_BASE_ADDR),
      .N(16)
   ) pwm2_16bit(
      //    Input ports definition
      .sys_clk       ( sys_clk                  ),
      .sys_clk_div   ( sys_clk_div              ),
      .sys_clk_en    ( chip_lp_mode             ),
      .sys_rst_n     ( sys_rst_n                ),
      .sys_addr      ( cpu_req_addr             ),
      .sys_wr_en     ( sfr_wr_en                ),
      .sys_sw_value  ( cpu_wr_data              ),
      //    Output ports definition
      .sfr_rd_dout   ( pwm2_sfr_rd_bus          ),
      .pr_event      ( pwm2_pr_if               ),
      .dc_event      ( pwm2_dc_if               ),
      .ph_event      ( pwm2_ph_if               ),
      .of_event      ( pwm2_of_if               ),
      .pwm_out       ( pwm2_out                 )
   );

   //==========================
   // SFR Bus
   //==========================
   assign sfr_rd_bus = pwm0_sfr_rd_bus | pwm1_sfr_rd_bus | pwm2_sfr_rd_bus |
                       tmr0_sfr_rd_bus | tmr1_sfr_rd_bus | dco_sfr_rd_bus  |
                       chip_sfr_rd_bus ;


endmodule : mcu_v2_pipeline