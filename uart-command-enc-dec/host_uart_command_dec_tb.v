
`timescale 1ns/1ps
module host_uart_command_dec_tb;

  // Inputs
  reg clk;
  reg reset;
  reg[1023:0] input_data;
  reg start;

  // Outputs
  wire[255:0] output_data;
  wire done;
  wire error;
  wire[15:0] cmd_select;

  // Instantiate the module under test
  host_uart_command_dec dut (
    .clk(clk),
    .reset(reset),
    .input_data(input_data),
    .start(start),
    .output_data(output_data),
    .done(done),
    .error(error),
    .cmd_select(cmd_select)
  );

  parameter ENCRYPT_ENABLE = 72'h0101FFFFFFFFFFFF01;
  parameter ENCRYPT_DISABLE = 72'h0001FFFFFFFFFFFF01;
  parameter ENCRYPT_BAD_FORMAT_TARGET = 72'h0001FFFFFF27FFFF01;
  parameter ENCRYPT_BAD_FORMAT_SIZE = 72'h0002FFFFFFFFFFFF01;
  parameter READ_YAW = 56'hFF27FF27FF2703;
  parameter INVALID_COMMAND = 56'hFF27FF27FF2705;

  // Clock generation
  always #5 clk = ~clk;

  // Test stimulus
  initial begin
    // Initialize inputs
    clk = 0;
    reset = 1;
    input_data = 0;
    start = 0;

    // Wait for reset to deassert
    #10 reset = 0;
    
    input_data = ENCRYPT_ENABLE;
    #5;
    start = 1;
    #10;
    start = 0;

    while(!done) begin
      #10;
    end

    #20;
    input_data = ENCRYPT_DISABLE;
    #5;
    start = 1;
    #10;
    start = 0;

    while(!done) begin
      #10;
    end

    #20;
    input_data = READ_YAW;
    #5;
    start = 1;
    #10;
    start = 0;

    while(!done) begin
      #10;
    end

    #20;
    input_data = READ_YAW;
    #5;
    start = 1;
    #10;
    start = 0;

    while(!done) begin
      #10;
    end

    #20;
    //Issue a reset
    reset = 1;
    #10;
    reset = 0;
    input_data = ENCRYPT_BAD_FORMAT_TARGET;
    #5;
    start = 1;
    #10;
    start = 0;

    while(!done) begin
      #10;
    end

    #20;
    input_data = ENCRYPT_BAD_FORMAT_SIZE;
    #5;
    start = 1;
    #10;
    start = 0;

    while(!done) begin
      #10;
    end

    #20;
    input_data = INVALID_COMMAND;
    #5;
    start = 1;
    #10;
    start = 0;

    while(!done) begin
      #10;
    end

    // Apply test vectors
    
  end

endmodule