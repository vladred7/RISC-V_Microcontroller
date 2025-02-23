//######################################## Header ########################################
//# Author: Vlad Rosu                                                                    #
//# Description: This module represents the memory map decode use to decode the source   #
//#              segment of the requested address                                        #
//########################################################################################

module mem_map_dec(
   //    Input ports definition
   input  [31:0]  sys_address,
   //    Output ports definition
   output         en_mem_sfr,
   output         en_mem_io,
   output         en_mem_undef,
   output         en_mem_dfm,
   output         en_mem_pfm
);
   
   //logic cross_sfr_io_undef;

   //assign cross_sfr_io_undef = &sys_address[31:30];


   assign en_mem_sfr   = (&sys_address[31:12]) & sys_address[11];
   assign en_mem_io    = (&sys_address[31:12]) & (~sys_address[11]);
   // FIXME VR: these lines should by used for the MPU memory map
   // assign en_mem_undef = cross_sfr_io_undef & (~en_mem_sfr) & (~en_mem_io);
   // assign en_mem_dfm   = ~|{en_mem_pfm, cross_sfr_io_undef};
   // assign en_mem_pfm   = ~|sys_address[31:28];
   
   assign en_mem_dfm   = (sys_address >= 32'h1000_0000) & (sys_address <= 32'h1000_FFFF);
   assign en_mem_pfm   = (sys_address >= 32'h0000_0000) & (sys_address <= 32'h0000_FFFF);
   assign en_mem_undef = ~|{en_mem_sfr,en_mem_io,en_mem_dfm,en_mem_pfm};

endmodule : mem_map_dec