`define MMODE_READ   0
`define MMODE_WRITE  1

`define PHASE_GETCMD 2'b00
`define PHASE_GETARG 2'b01
`define PHASE_EXEC1  2'b10
`define PHASE_EXEC2	 2'b11

module command_processor(

	input clk,			  // clock
	input mem_response,   // used for memory sync

	input [15:0]mem_read, // values from memory are received here

	output reg [15:0]mem_locator = 0, // this is used to access memory cells.
	output reg [15:0]mem_write = 0,   // this value is written by 

	output reg mem_mode  =  0,		  // 1: write, 0: read
	output reg mem_block = 0,		  // do nothing - await response from memory

	output reg done = 0   // lit up when finish statement is encountered
);
	/*
	 * Registers
	 */

	reg [15:0]reg_left  = 16'b0;
	reg [15:0]reg_right = 16'b0; // general-purpose reg; these are equivalent 
						         // to rax..rdx but there are only 2 for simplicity
						         
	reg [15:0]cmd_ptr   = 0;     // instruction being executed
	reg [15:0]stk_ptr   = 255;   // end of stack

	reg [1:0]cpu_phase  = 0;     // 0 0 : read instruction;
							     // 0 1 : read argument;
							     // 1 0 : command exec phase 1, read/write;
							     // 1 1 : command exec phase 2
	reg [15:0]command;
	reg [15:0]argument;
	
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
				
				mem_locator = cmd_ptr + 1;
				mem_block = 1;
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
				16'hBBBB: begin
					// skip next phase and cmd_ptr increment
					cmd_ptr = argument;
					cpu_phase += 1;
				end
				16'hB061: begin // jump if LEFT > RIGHT
					if(reg_left > reg_right) begin
						cmd_ptr = argument
					end
					else begin
						cmd_ptr += 2;
					end
					cpu_phase += 1;
				end
				16'hB051: begin // jump if LEFT < RIGHT
					if(reg_left < reg_right) begin
						cmd_ptr = argument
					end
					else begin
						cmd_ptr += 2;
					end
					cpu_phase += 1;
				end
				16'hB0E1: begin // jump if LEFT == RIGHT
					if(reg_left == reg_right) begin
						cmd_ptr = argument
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
endmodule

/*
 FLAGS:

 []

 COMMAND CODE TABLE

 * assignment
  
F000 - move from LEFT to given addr
F001 - move from RIGHT to given addr

2000 - move from given addr to LEFT
2001 - move from given addr to RIGHT

C021 - copy value from LEFT to RIGHT
C120 - copy value from RIGHT to LEFT

E300 - swap registers

 * pointers - 1 memory op per cycle

FA10 - move *RIGHT to LEFT
FA01 - move *LEFT to RIGHT

2A10 - move LEFT to *RIGHT
2A01 - move RIGHT to *LEFT

 * all constants are presumed to be stored in memory
 * commands that add const to register or load const into it
 * are omitted because they are redundant.

 * addition
 
ADD0 - add value from given addr to LEFT
ADD1 - add value from given addr to RIGHT

AA10 - add *RIGHT to LEFT
AA01 - addd *LEFT to RIGHT

1A00 - add LEFT and RIGHT, save to LEFT
1A01 - add LEFT and RIGHT, save to LEFT

 * subtraction
 
5B70 - sub value from given addr from LEFT
5B71 - sub value from given addr from RIGHT

5A10 - sub *RIGHT from LEFT
5A01 - sub *LEFT from RIGHT

0510 - sub RIGHT from LEFT, save to LEFT
1500 - sub LEFT from RIGHT, save to LEFT

 * misc math 
 
11E0 - invert LEFT
11E1 - invert RIGHT

 * flow control

BBBB - unconditional jump

B061 - jump if LEFT > RIGHT
B051 - jump if LEFT < RIGHT
B0E1 - jump if LEFT == RIGHT

* stack

5AD0 - push LEFT
5AD1 - push RIGHT
5670 - pop to LEFT
5671 - pop to RIGHT
567E - pop to nowhere

CA11 - call function (lowest implementation priority)
E7FC - exit function ("ret")

C575 - call system (probably going to be button input or indicators)
	* write something to indicators
	* await button input

FFFF - end program

*/
