//######################################## Header ########################################
//# Author: Vlad Rosu                                                                    #
//# Description: A parameterizable program counter module                                #
//########################################################################################

module cpu_program_counter  #(
   parameter ADDR_WIDTH = 32
)(
   //    Input ports definition
   input                   clk,
   input                   rst_n,
   input                   ld,
   input  [ADDR_WIDTH-1:0] pc_in,
   //    Output ports definition
   output [ADDR_WIDTH-1:0] pc_out
);
   
   logic [ADDR_WIDTH-1:0] pc_val;

   always_ff @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
         pc_val <= '0;
      end else if(ld) begin
         pc_val <= pc_in;
      end
   end

   assign pc_out = pc_val;

   `ifdef DESIGNER_ASSERTIONS
      //TODO add assertions
   `endif

endmodule : cpu_program_counter