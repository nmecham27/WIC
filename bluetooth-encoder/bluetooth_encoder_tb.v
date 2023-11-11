
`timescale 1ns/1ps
module bluetooth_encoder_tb;

  // Inputs
  reg [32:0] input_data;
  reg [3:0] command_select;
  reg start;
  reg clk;
  reg reset;

  // Outputs
  wire [143:0] output_data;
  wire done;

  // Instantiate the module under test
  bluetooth_encoder dut (
    .input_data(input_data),
    .command_select(command_select),
    .start(start),
    .clk(clk),
    .reset(reset),
    .output_data(output_data),
    .done(done)
  );

  // Clock generation
  always begin
    clk = 0;
    #5;
    clk = 1;
    #5;
  end

  // Reset generation
  initial begin
    reset = 1;
    #10;
    reset = 0;
  end

  // Test stimulus
  initial begin
    // Provide test vectors here
    input_data = 32'h12345678;
    command_select = 4'b001;
    start = 0;
    #10
    start = 1;
    #10;
    start = 0;
    #20;
    input_data = 32'h12345678;
    command_select = 4'h2;
    #5;
    start = 1;
    #5;
    start = 0;
  end

  // Monitor
  always @(posedge clk) begin
    // Add code here to monitor and display the values of output_data and done
  end

endmodule