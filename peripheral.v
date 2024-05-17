module clk_div #(parameter DIV = 2) (

	// clock divider; toggles output on each counter reset.
	
	input wire clkin,
	output reg clkout = 0
	
	);

	reg [$clog2(DIV)-1:0]counter = 0;

	always @(posedge clkin) begin
		if(counter == DIV-1) begin
			counter <= 0;
			clkout <= ~clkout;
		end
		else begin
			counter <= counter + 1;
		end
	end
endmodule

module debouncer #(parameter TOLERANCE = 8) (

	// waits for N consecutive button readings of same value before switching to it.
	
	input wire clk,
	input wire button,

	output out = 0
	);

	reg [$clog2(TOLERANCE)-1:0]counter = 0;

	always @(posedge clk) begin
		if (button == ~out) begin
			if (counter == TOLERANCE-1) begin
				counter <= 0;
				out <= ~out;
			end
			else begin
				counter += counter + 1;	
			end
		end
		else begin
			counter <= 0;
		end
	end
	
endmodule

module peripheral_io(

	input clk,

	input [7:0]switch,
	input button,
	
	input [15:0]word,
	input [15:0]cmd,
	input request,

	output reg [6:0]segments = 0,
	output reg [7:0]digits = 0,
	output reg [7:0]led = 0,
	output reg [15:0]keycode = 0,
	output reg response = 0
	
	);
	
	reg [6:0]indicator_word[7:0];
	reg [6:0]symbol_table[15:0];
	
	initial begin
		symbol_table[0] = 7'b1000000; // 0
		symbol_table[1] = 7'b1111001; // 1
		symbol_table[2] = 7'b0100100; // 2
		symbol_table[3] = 7'b0110000; // 3
		symbol_table[4] = 7'b0011001; // 4
		symbol_table[5] = 7'b0010010; // 5
		symbol_table[6] = 7'b0000010; // 6
		symbol_table[7] = 7'b1111000; // 7
		symbol_table[8] = 7'b0000000; // 8
		symbol_table[9] = 7'b0010000; // 9
		symbol_table[10] = 7'b0001000; // A
		symbol_table[11] = 7'b0000011; // B
		symbol_table[12] = 7'b1000110; // C
		symbol_table[13] = 7'b0100001; // D
		symbol_table[14] = 7'b0000110; // E
		symbol_table[15] = 7'b0001110; // F
	end
	
	reg reset = 0; // make response generate both negative and positive edge on each request
	wire blink_clk;
	clk_div #(.DIV(4096)) clk_divider (.clkin(clk),
						 			   .clkout(blink_clk)
						  			  );

	always @(negedge clk) begin
		if (reset) begin
			reset <= 0;
			response <= 0;
		end 
		else if (request & ~response) begin
			response = 1;
			case (cmd)
			16'hD000: begin
				// for (int i = 0; i < 4; i = i + 1) begin
				//     indicator_word[i] = symbol_table[word[(4*i+3):(4*i)]];
				// end
				indicator_word[0] = symbol_table[word[3:0]];
				indicator_word[1] = symbol_table[word[7:4]];
				indicator_word[2] = symbol_table[word[11:8]];
				indicator_word[3] = symbol_table[word[15:12]];
			end
			16'h1000: begin
				keycode[8:0] = {7'b0, button, switch};
			end
			endcase	
			reset = 1;	
		end
	end

	reg [2:0]blink_counter = 0;
	always @(posedge blink_clk) begin
		digits <= ~(8'b00000001 << blink_counter);
		segments <= indicator_word[blink_counter];
		
		blink_counter <= blink_counter + 1;
	end
	
endmodule

// D000 - display number
// 1000 - get number combination
// D001..4 - display digit 1..4 only
// DC01..4 - clear and display given digit segment-wise
//           (AND NOT every segment with first 8 bits of word, then OR them wiht other 8 bits)
// B000 -  
// F000
