`define SIZE 256*256

module rom_loader(
// loads file into memory when powered
	input clk,
	input memory_response,

	output reg [15:0]write_bus,
	output wire [15:0]locator_bus,
	output reg memory_request,
	output reg done,
	output reg memory_mode
	);
	
	reg [15:0]temp[`SIZE:0];
	reg [15:0]progress;
	reg [15:0]file_size;
	
	assign locator_bus = progress;

	initial begin
		$readmemh("program.txt", temp);
		
		// First symbol in ROM is the program's length.
		// it is not loaded into memory.
		//
		// Example:
		//
		//   0007
		//
		// 0 2000
		// 1 0006
		// 2 ADD0
		// 3 0000
		// 4 BBBB
		// 5 0002
		// 6 0001
		//
		// this program loads 1 into LEFT and 
		// increments it endlessly. 
		
		file_size = temp[0];
		progress = 0;
		
		memory_mode = 1; // Write
		memory_request = 0;
		done = 0;
	end
	
	always @(posedge clk) begin
		if(~done & ~memory_request) begin
			if(progress <= file_size) begin
				write_bus = temp[progress+1];
			end
			else if(progress == file_size) begin 
				write_bus = 0;
			end
			
			if(progress == `SIZE-1) begin
				done = 1;
				memory_mode    = 0;
				progress       = 0;
				write_bus      = 0;
			end
			else begin
			memory_request = 1;
			end
		end
	end

	always @(negedge memory_response) begin
		if(memory_request & ~done) begin
			memory_request = 0;
			progress = progress+1;
		end
	end
endmodule
