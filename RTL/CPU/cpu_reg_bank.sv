module cpu_reg_bank #(
   parameter ADDR_WIDTH = 5,
   parameter DATA_WIDTH = 32
)( 
   //    Input ports definition
	input                   clk,
	input                   rst_n,
	input  [ADDR_WIDTH-1:0] a1,     //address port 1
	input  [ADDR_WIDTH-1:0] a2,     //address port 2
	input  [ADDR_WIDTH-1:0] a3,     //address port 3
   input                   wen3,   //write enable for port 3
	input  [DATA_WIDTH-1:0] wd3,    //write data for port 3
   //    Output ports definition
   output [DATA_WIDTH-1:0] rd1,    //read data for port 1
   output [DATA_WIDTH-1:0] rd2     //read data for port 2
);

   import pkg_cpu_typedefs::*;
   
   //Declare the register bank as an array of registers
   logic [DATA_WIDTH-1:0] reg_bank[1:(2**ADDR_WIDTH)-1]; //note: address 0 will always be hardwired to 0 so real bank is defined without index 0

   //Read Channels
   assign rd1 = (a1 == 0) ? '0 : reg_bank[a1];
   assign rd2 = (a2 == 0) ? '0 : reg_bank[a2];

   //Write Channel
   always_ff @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         for (int i = 1; i < (2**ADDR_WIDTH); i++) begin
            reg_bank[i] <= '0; //if reset is asserted reset all the memory locations to 0
         end
      end else if(wen3)
         reg_bank[a3] <= wd3;
   end
      
   `ifdef DESIGNER_ASSERTIONS
      a_a1_noteq_a3: assert(a1 !== a3) else $warning($sformatf("WARNING SVA: a3 is equal to a1! addr=%0h",a3));
      a_a2_noteq_a3: assert(a2 !== a3) else $warning($sformatf("WARNING SVA: a3 is equal to a2! addr=%0h",a3));
      ap_a3_noteq_0: assert property(disable iff (!rst_n)  @(posedge clk)  wen3 |-> (a3 !== 0);) else $error($sformatf("ERROR SVA: Cannot write address 0 because it is hardwired to 0's!!!"));
   `endif

endmodule : cpu_reg_bank