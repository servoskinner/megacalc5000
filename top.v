`timescale 1 ns / 100 ps

module group(
	input clk,
	input button,
	input [7:0]switch_bus,

	output wire [7:0]switch,
	output wire [6:0]segments,
	output wire [7:0]digits,
	output wire [7:0]led
);
	assign led = switch;

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
	// memory 
	memory            mem(.clk(clk),
			              .request(request_wire),
			              .mode_flag(mode_wire),
			              .locator(locator_bus),
			              .write_bus(write_bus),
			              .read_bus(read_bus),
			              .response(response_wire));
	// 
	static_loader     loader(.clk(clk),
					      .memory_request(request_loader),
					      .memory_response(response_wire),
					      .write_bus(write_loader),
					      .locator_bus(locator_loader),
					      .memory_mode(mode_loader),
					      .done(loader_done));
	// CPU
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
	// led & switch control
	peripheral_io  periph(.clk(cpu_clock),

						  .switch(switch),
						  .button(button),
						  .segments(segments),
						  .digits(digits),
							
						  .request(io_request),
						  .response(io_response),
						  .cmd(io_command),
						  .word(io_word),
						  .keycode(io_keycode));
endmodule
