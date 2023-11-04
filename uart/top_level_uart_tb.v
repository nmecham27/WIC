`timescale 1ns/1ps
module top_level_uart_tb;
  reg clk;
  reg reset;
  reg [7:0] uart_tx;
  reg start_transmit;
  reg load_data;
  wire [7:0] uart_rx;
  wire valid;
  wire tx_done;

  // Instantiate the top_level_uart module
  top_level_uart #(
    .BAUD_RATE(9600),
    .CLOCK_FREQ(38400000)
  ) dut (
    .clk(clk),
    .reset(reset),
    .uart_tx(uart_tx),
    .start_transmit(start_transmit),
    .load_data(load_data),
    .uart_rx(uart_rx),
    .valid(valid),
    .tx_done(tx_done)
  );

  // Generate a 38.4 MHz base clock
  always #13.02 clk = ~clk;

  // Initialize signals
  initial begin
    clk = 0;
    reset = 1;
    uart_tx = 8'h27;
    start_transmit = 0;
    load_data = 0;

    #100; // Wait for 100 time units

    reset = 0; // Deassert reset

    #100; // Wait for 100 time units

    load_data = 1; // Load data

    #100; // Wait for 100 time units
    load_data = 0; // Stop loading data

    start_transmit = 1; // Start transmitting

    #100; // Wait for 100 time units

    start_transmit = 0; // Stop transmitting

    while(!tx_done) begin
	#100;
    end

    uart_tx = 8'h33;
    #100; // Wait for 100 time units

    load_data = 1; // Load data

    #100; // Wait for 100 time units
    load_data = 0; // Stop loading data

    start_transmit = 1; // Start transmitting

    #100; // Wait for 100 time units

    start_transmit = 0; // Stop transmitting
    #100; // Wait for 100 time units

    // End simulation
  end

  // Display received data
  always @(posedge clk) begin
    if (valid) begin
      $display("Received data: %h", uart_rx);
    end
  end

endmodule