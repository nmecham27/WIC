`timescale 1us/1ps
module baud_rate_generator_tb;

  // Parameters
  parameter CLK_FREQ = 192000;
  parameter BAUD_RATE = 9600;

  // Inputs
  reg clk;
  reg reset;
  
  // Outputs
  wire baud_out;
  
  // Instantiate the DUT
  baud_rate_generator #(
    .BAUD_RATE(BAUD_RATE),
    .CLOCK_FREQ(CLK_FREQ)
  ) dut (
    .clk(clk),
    .reset(reset),
    .baud_out(baud_out)
  );
  
  // Clock generation
  always #5 clk = ~clk;
  
  // Stimulus
  initial begin
    clk = 0;
    reset = 1;
    #10;
    reset = 0;
    #100;
    $display("End of simulation");
  end
  
endmodule