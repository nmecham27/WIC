`timescale 1ns/1ps
module uart_rx_tb;

  reg clk;
  reg rst;
  reg rx;
  reg soft_reset;
  wire [7:0] data;
  wire valid;

  // Instantiate uart_rx module
  uart_rx #(
    .BAUD_RATE(9600),
    .CLOCK_FREQ(38400000)
  ) dut (
    .clk(clk),
    .rst(rst),
    .rx(rx),
    .soft_reset(soft_reset),
    .data(data),
    .valid(valid)
  );

  // Clock generation
  always begin
    #13.02;
    clk = ~clk;  // Generate a 38.4 MHz clock
  end

  // Testbench code to provide inputs
  initial begin
    // Initialize inputs
    soft_reset = 0;
    clk = 0;
    rst = 1;
    rx = 1;

    // Wait for a few clock cycles
    #100;

    // De-assert reset
    rst = 0;
    #30 rx = 0;
    #200 rx = 1;
    // Wait for a few clock cycles
    #500;
    // Finish simulation
    #10;
  end

endmodule