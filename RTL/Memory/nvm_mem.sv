//######################################## Header ########################################
//# Author: Vlad Rosu                                                                    #
//# Description: Standard model of a parameterizable memory                              #
//########################################################################################

module nvm_mem #(
   parameter MEM_ADDR_WIDTH = 32,
   parameter MEM_DATA_WIDTH = 32
) (
   //    Input ports definition
   input                         clk,
   input                         we,
   input    [MEM_ADDR_WIDTH-1:0] addr,
   input    [MEM_DATA_WIDTH-1:0] wd,
   //    Output ports definition
   output   [MEM_DATA_WIDTH-1:0] rd
);

   //Define the memory map
   logic [MEM_DATA_WIDTH-1:0] mem_map[0:(2**MEM_ADDR_WIDTH)-1];
//TODO should I remodel this to be a bi-directional port RAM?
   always_ff @(posedge clk)
      if (we)
         mem_map[addr] <= wd;

   assign rd = mem_map[addr]; //FIXME: Look at page 395(417)

endmodule : nvm_mem