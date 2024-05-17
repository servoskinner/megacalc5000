`define SIZE 256*256

module rom_reader(
// scans all memory cells when powered
	input clk,
	input memory_response,

	output wire [15:0]locator_bus,
	output reg memory_request,
	output reg done,
	output reg memory_mode // this is always set to 0
	);
	
	reg [15:0]progress;
	assign locator_bus = progress;

	initial begin
		progress = 0;

		memory_mode = 0; // Read
		memory_request = 0;
		done = 0;
	end
	
	always @(posedge clk) begin
		if(~done & ~memory_request) begin
				memory_request = 1;
		end
	end

	// After receiving memory response, prepare to display next cell;
	always @(negedge memory_response) begin
		if(memory_request & ~done) begin
			memory_request = 0;
			progress = progress+1;
			
			if(progress == 0) begin
				done = 1;
				progress = 0;
			end	
		end
	end
endmodule
