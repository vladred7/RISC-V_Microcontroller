//######################################## Header ########################################
//# Author: Vlad Rosu                                                                    #
//# Description: List containing the order of compilation for the chip modules           #
//########################################################################################

// Compilation tree for the MCU Modules Hierachy
//
// MCU--+---Memory----+--pkg_sfrs_definition.sv
//      |             +--sfr_module_v1.sv
//      |             +--sfr_map.sv
//      |             +--nvm_mem.sv
//      |       
//      +-----CPU-----+--pkg_cpu_typedefs.sv
//      |             +--cpu_control_unit.sv
//      |             +--cpu_reg_bank.sv
//      |             +--cpu_alu.sv
//      |             +--cpu_sign_extend_unit.sv
//      |             +--cpu_program_counter.sv
//      |             +--cpu_multicycle_v1.sv
//      |
//      +--Clk_presc--+--clk_prescaller_v1.sv
//      |
//      +----Timer----+--timer_nbit_v1.sv
//      |
//      +-----PWM-----+--pwm_nbit_v1.sv
//      |
//      +----UART-----+--

//TODO Add the order of compilation