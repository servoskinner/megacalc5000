`define SIZE 256*256

`define MMODE_READ   0
`define MMODE_WRITE  1

module memory(
	input clk,
	
	input request,
	input mode_flag,
	input [15:0] locator,
	input [15:0] write_bus,

	output reg [15:0] read_bus = 0,
	output reg response = 0
);
	reg [15:0]memory[`SIZE-1:0];
	reg reset = 0; // make response generate both negative and positive edge on each request

	always @(negedge clk) begin
		if (reset) begin
			reset <= 0;
			response <= 0;
		end
		else if (request & ~response) begin
			response = 1;
			case(mode_flag)
			`MMODE_READ: read_bus = memory[locator];
			`MMODE_WRITE: memory[locator] = write_bus;
			endcase
			reset = 1;
		end
	end	
endmodule
