`timescale 1 ns / 100 ps

module group();
	reg clk = 1'b0;

	wire request_wire;
	wire request_loader;
	wire request_reader;
	wire request_cpu;
	assign request_wire = request_loader
						| request_reader
						| request_cpu;
	
	wire response_wire;
	
	wire mode_wire;
	wire mode_loader;
	wire mode_reader;
	wire mode_cpu;
	
	assign mode_wire = mode_loader
					 | mode_reader
				     | mode_cpu;

	wire [15:0]locator_bus;
	wire [15:0]locator_loader;
	wire [15:0]locator_reader;
	wire [15:0]locator_cpu;
	
	assign locator_bus = locator_loader
					   | locator_reader
					   | locator_cpu;

	
	wire [15:0]read_bus;

	wire [15:0]write_loader;
	wire [15:0]write_cpu;
	wire [15:0]write_bus;

	assign write_bus = write_loader
				     | write_cpu;

	wire reader_clock;
	wire cpu_clock;
	
	wire loader_done;
	wire cpu_done;

	assign cpu_clock    = clk & loader_done;
	assign reader_clock = clk & loader_done & cpu_done;

	wire io_request;
	wire io_response;
	wire [15:0]io_command;
	wire [15:0]io_word;
	wire [15:0]io_keycode;

	wire button;
	wire switch[7:0];
	wire segments[6:0];
	wire digits[7:0];
	wire led[7:0];

	wire [7:0]switch_bus = {switch[0],
							switch[1],
							switch[2],
							switch[3],
							switch[4],
							switch[5],
							switch[6],
							switch[7]
							};
	wire [6:0]segment_bus = {segments[0],
							 segments[1],
							 segments[2],
							 segments[3],
							 segments[4],
							 segments[5],
							 segments[6]
							 };
	wire [7:0]digit_bus  = {digits[0],
							digits[1],
							digits[2],
							digits[3],
							digits[4],
							digits[5],
							digits[6],
							digits[7]
						   };
						   
	reg [7:0]dummy = 8'hED;
	assign switch_bus = dummy;

	always begin
		#1 clk = ~clk;
	end

	initial begin
		$dumpvars;
		#1000000 $finish;
	end
	
	memory            mem(.clk(clk),
			              .request(request_wire),
			              .mode_flag(mode_wire),
			              .locator(locator_bus),
			              .write_bus(write_bus),
			              .read_bus(read_bus),
			              .response(response_wire));

	static_loader     loader(.clk(clk),
					      .memory_request(request_loader),
					      .memory_response(response_wire),
					      .write_bus(write_loader),
					      .locator_bus(locator_loader),
					      .memory_mode(mode_loader),
					      .done(loader_done));

	command_processor cpu(.clk(cpu_clock),
						  .mem_response(response_wire),
						  .mem_read(read_bus),
						  .mem_locator(locator_cpu),
						  .mem_write(write_cpu),
						  .mem_mode(mode_cpu),
						  .mem_block(request_cpu),

						  .periph_block(io_request),
						  .periph_response(io_response),
						  .periph_command(io_command),
						  .periph_argument(io_word),
						  .periph_read(io_keycode),
						  .done(cpu_done));

	peripheral_io  periph(.clk(cpu_clock),

						  .switch(switch_bus),
						  .button(button),
						  .segments(segment_bus),
						  .digits(digit_bus),
							
						  .request(io_request),
						  .response(io_response),
						  .cmd(io_command),
						  .word(io_word),
						  .keycode(io_keycode));

	rom_reader     reader(.clk(reader_clock),
				          .memory_response(response_wire),
				          .locator_bus(locator_reader),
				          .memory_request(request_reader),
				          .memory_mode(mode_reader));
endmodule
