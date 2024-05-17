`define SIZE 256*256

module static_loader(
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
		temp[0 ] = 16'hBBBB;
		temp[1 ] = 16'h0007;
		
		temp[2 ] = 16'h1000;
		temp[3 ] = 16'hD000;
		temp[4 ] = 16'b0000000100000000;
		temp[5 ] = 16'h0000;
		temp[6 ] = 16'h2000;
		
		temp[7 ] = 16'h2000;
		temp[8 ] = 16'h0002;
		temp[9 ] = 16'hC500;
		temp[10] = 16'h2000;
		temp[11] = 16'h0004;
		temp[12] = 16'hAAA1;
		temp[13] = 16'hB0E1;
		temp[14] = 16'h0011;
		temp[15] = 16'hBBBB;
		temp[16] = 16'h0007;
		
		temp[17] = 16'h2001;
		temp[18] = 16'h0005;
		temp[19] = 16'h2000;
		temp[20] = 16'h0002;
		temp[21] = 16'hC500;
		temp[22] = 16'h2000;
		temp[23] = 16'h0003;
		temp[24] = 16'hC500;
		temp[25] = 16'hBBBB;
		temp[26] = 16'h0007;
		
		file_size = 26;
		progress = 0;
		
		memory_mode = 1; // Write
		memory_request = 0;
		done = 0;
	end
	
	always @(posedge clk) begin
		if(~done & ~memory_request) begin
			if(progress < file_size) begin
				write_bus = temp[progress];
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
