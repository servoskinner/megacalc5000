`define MMODE_READ   0
`define MMODE_WRITE  1

`define PHASE_GETCMD 2'b00
`define PHASE_GETARG 2'b01
`define PHASE_EXEC1  2'b10
`define PHASE_EXEC2  2'b11

`define SIZE 256*256

module command_processor(

	input clk,			  // clock
	input mem_response,   // await memory response and do nothing
	input periph_response,

	input [15:0]mem_read, // values from memory are received here

	output reg [15:0]mem_locator = 0, // this is used to access memory cells.
	output reg [15:0]mem_write = 0,   // this value is written by 

	output reg mem_mode  =  0,		  // 1: write, 0: read
	output reg mem_block = 0,		  // do nothing - await response from memory
	output reg periph_block = 0,

	output reg done = 0  // lit up when finish statement is encountered
);
	/*
	 * Registers
	 */

	reg [15:0]reg_left  = 16'b0;
	reg [15:0]reg_right = 16'b0; // general-purpose reg; these are equivalent 
						         // to rax..rdx but there are only 2 for simplicity
						         
	reg [15:0]cmd_ptr   = 0;     // instruction being executed
	reg [15:0]stk_ptr   = `SIZE-1;   // end of stack (next free cell; decreases as values are pushed)

	reg [1:0]cpu_phase  = 0;     // 0 0 : read instruction;
							     // 0 1 : read argument;
							     // 1 0 : command exec phase 1, read/write;
							     // 1 1 : command exec phase 2
	reg [15:0]command;
	reg [15:0]argument;

	wire block;
	assign block = mem_block | periph_block;
	
	initial begin
		// 
	end

	always @(posedge clk) begin // update memory on negedge
		if(~mem_block & ~done) begin
			case(cpu_phase)
			`PHASE_GETCMD: begin
				// disables memory write if it was
				// active.
				mem_mode = `MMODE_READ;
				mem_locator = cmd_ptr;
				mem_block = 1;
			end
			`PHASE_GETARG: begin
				command = mem_read;

				case(command) // skip arg request if it's irrelevant (inter-register ops)
				
				16'hEC6E,
				16'hC021,
				16'hC120,
				16'h0A10,
				16'h0A11,
				16'h0510,
				16'h0511,
				16'h1500,
				16'h1501,
				16'hFFFF: begin
					// do nothing
				end
				default: begin
					mem_locator = cmd_ptr + 1;
					mem_block = 1;
				end
				endcase
			end
			`PHASE_EXEC1:  begin
				argument = mem_read;

				case(command)
					//
				16'hF000: begin // move LEFT to given address
					mem_locator = argument;
					mem_write = reg_left;
				    // /!\ set write mode AFTER setting
				    //     locator and value!
					mem_mode = `MMODE_WRITE;
					mem_block = 1;
				end
				16'hF001: begin // move RIGHT to given address
					mem_locator = argument;
					mem_write = reg_right;
					// /!\ set write mode AFTER setting
					//     locator and value!
					mem_mode = `MMODE_WRITE;
					mem_block = 1;
				end
				16'h2000,
				16'h2001,
				16'hADD0,
				16'hADD1,
				16'h5B70,
				16'h5B71: begin // move from given address to LEFT
					mem_mode = `MMODE_READ;
					mem_locator = argument;
					mem_block = 1;
				end	

				// inter-register arithmetics and copying - skip next phase:

				16'hEC6E: begin	// exchange register contents
					reg_right <= reg_left;
					reg_left <= reg_right;

					cpu_phase += 1;
					cmd_ptr += 1;
				end
				16'hC021: begin // copy LEFT to RIGHT
					reg_right = reg_left;

					cpu_phase += 1;
					cmd_ptr += 1;
				end
				16'hC120: begin	// copy RIGHT to LEFT
					reg_left = reg_right;

					cpu_phase += 1;
					cmd_ptr += 1;
				end
				16'h0A10: begin // add LEFT and RIGHT, store to LEFT
					reg_left += reg_right;
					
					cpu_phase += 1;
					cmd_ptr += 1;
				end
				16'h0A11: begin // add LEFT and RIGHT, store to RIGHT
					reg_right += reg_left;
					
					cpu_phase += 1;
					cmd_ptr += 1;
				end
				16'h0510: begin	// subtract RIGHT from LEFT, save to LEFT
					reg_left -= reg_right;
				
					cpu_phase += 1;
					cmd_ptr += 1;
				end
				16'h0511: begin	// subtract RIGHT from LEFT, save to RIGHT
					reg_right = reg_left - reg_right;

					cpu_phase += 1;
					cmd_ptr += 1;
				end
				16'h1500: begin	// subtract LEFT from RIGHT, save to LEFT
					reg_left = reg_right - reg_left;

					cpu_phase += 1;
					cmd_ptr += 1;
				end
				16'h1501: begin // subtract LEFT from RIGHT, save to RIGHT			
					reg_right -= reg_left;

					cpu_phase += 1;
					cmd_ptr += 1;
				end

				// flow control - skip next phase;
				
				16'hBBBB: begin
					cmd_ptr = argument;
					cpu_phase += 1;
				end
				16'hB061: begin // jump if LEFT > RIGHT
					if(reg_left > reg_right) begin
						cmd_ptr = argument;
					end
					else begin
						cmd_ptr += 2;
					end
					cpu_phase += 1;
				end
				16'hB051: begin // jump if LEFT < RIGHT
					if(reg_left < reg_right) begin
						cmd_ptr = argument;
					end
					else begin
						cmd_ptr += 2;
					end
					cpu_phase += 1;
				end
				16'hB0E1: begin // jump if LEFT == RIGHT
					if(reg_left == reg_right) begin
						cmd_ptr = argument;
					end
					else begin
						cmd_ptr += 2;
					end
					cpu_phase += 1;
				end
				16'hFFFF: begin // shutdown
					done = 1;
					mem_write = 0;
					mem_locator = 0;
					mem_mode = 0;
				end
				endcase
			end
			`PHASE_EXEC2:  begin
				case(command)
				16'h2000: begin // move from given address to LEFT
					reg_left    = mem_read;
				end
				16'h2001: begin // move from given address to RIGHT
					reg_right   = mem_read;
				end
				16'hADD0: begin // add from given address to LEFT
					reg_left   += mem_read;
				end
				16'hADD1: begin // add from given address to RIGHT
					reg_right  += mem_read;
				end
				16'h5B70: begin // subtract value at given address from LEFT
					reg_left   -= mem_read;
				end
				16'h5B71: begin // subtract value at given address from RIGHT
					reg_right  -= mem_read;
				end
				endcase
				// proceed to next command
				cmd_ptr += 2;
			end
			endcase
			// switch to next phase
			cpu_phase += 1;
		end
	end	

	// memory unblocker - continue exec when memory
	// displays requested cell
	always @(negedge mem_response) begin
		mem_block = 0;
	end	

	// peripheral unblocker
	always @(negedge periph_response) begin
		periph_block = 0;
	end
		
endmodule
