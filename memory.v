`define SIZE 256*256

`define MMODE_READ   0
`define MMODE_WRITE  1

module memory(
	input clk,
	
	input request_flag,
	input mode_flag,
	input [15:0] locator,
	input [15:0] write_bus,

	output reg [15:0] read_bus,
	output reg response_flag
);
	reg [15:0]memory[`SIZE-1:0];
	reg reset; // prevents multiple requests from stacking into one

	initial begin
		response_flag = 0;
		read_bus      = 0;
		reset         = 0;
	end

	always @(negedge clk) begin
		if(reset) begin
					reset = 0;
					response_flag = 0;
		end
		else if(request_flag & ~response_flag) begin
			response_flag = 1;
			case(mode_flag)
			`MMODE_READ: read_bus = memory[locator];
			`MMODE_WRITE: memory[locator] = write_bus;
			endcase
			reset = 1;
		end
	end	
endmodule
