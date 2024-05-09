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

	always begin
		#1 clk = ~clk;
	end

	initial begin
		$dumpvars;
		#1000000 $finish;
	end
	
	memory            mem(.clk(clk),
			              .request_flag(request_wire),
			              .mode_flag(mode_wire),
			              .locator(locator_bus),
			              .write_bus(write_bus),
			              .read_bus(read_bus),
			              .response_flag(response_wire));

	rom_loader     loader(.clk(clk),
					      .memory_response(response_wire),
					      .write_bus(write_loader),
					      .locator_bus(locator_loader),
					      .memory_request(request_loader),
					      .memory_mode(mode_loader),
					      .done(loader_done));

	command_processor cpu(.clk(cpu_clock),
						  .mem_response(response_wire),
						  .mem_read(read_bus),
						  .mem_locator(locator_cpu),
						  .mem_write(write_cpu),
						  .mem_mode(mode_cpu),
						  .mem_block(request_cpu),
						  .done(cpu_done));

	rom_reader     reader(.clk(reader_clock),
				          .memory_response(response_wire),
				          .locator_bus(locator_reader),
				          .memory_request(request_reader),
				          .memory_mode(mode_reader));
endmodule
