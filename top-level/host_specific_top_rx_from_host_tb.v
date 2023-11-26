`timescale 1ns/1ps
module host_specific_top_rx_from_host_tb;

  // Inputs
  reg clk;
  reg reset;
  reg [1023:0] input_data;
  reg send_packet;

  // Outputs
  wire [143:0] encoded_output;
  wire error;
  wire done;
  wire encrypt_decrypt_passthrough;

  // Instantiate the DUT
  host_specific_top_rx_from_host dut (
    .clk(clk),
    .reset(reset),
    .input_data(input_data),
    .send_packet(send_packet),
    .encoded_output(encoded_output),
    .encrypt_decrypt_passthrough(encrypt_decrypt_passthrough),
    .error(error),
    .done(done)
  );

  parameter ENCRYPT_ENABLE = 72'h0101FFFFFFFFFFFF01;
  parameter ENCRYPT_DISABLE = 72'h0001FFFFFFFFFFFF01;
  parameter ENCRYPT_BAD_FORMAT_TARGET = 72'h0001FFFFFF27FFFF01;
  parameter ENCRYPT_BAD_FORMAT_SIZE = 72'h0002FFFFFFFFFFFF01;
  parameter READ_YAW = 56'hFF27FF27FF2703;
  parameter INVALID_COMMAND = 56'hFF27FF27FF2705;

  // Clock generation
  //always begin
  //  clk = #5 ~clk;
  //end
  // Clock generation
  always #5 clk = ~clk;

  // Reset generation
  //initial begin
  //  reset = 1;
  //  #10 reset = 0;
  //end

  // Test case
  initial begin
    // Initialize inputs
    clk = 0;
    input_data = 0;
    send_packet = 0;
    reset = 1;
    #10;
    reset = 0;

    // Wait for reset to deassert
    #20;

    // Test case 1
    // Set inputs and wait for done signal
    input_data = ENCRYPT_ENABLE;
    send_packet = 1;
    #10;
    send_packet = 0;
    
    while(!done) begin
      #10;
    end

    // Test case 2
    // Set inputs and wait for done signal
    input_data = ENCRYPT_DISABLE;
    send_packet = 1;
    #10;
    send_packet = 0;

    while(!done) begin
      #10;
    end

    // Test case 3
    // Set inputs and wait for done signal
    input_data = READ_YAW;
    send_packet = 1;
    #10;
    send_packet = 0;

    while(!done) begin
      #10;
    end

    // Test case 4
    // Set inputs and wait for done signal
    input_data = INVALID_COMMAND;
    send_packet = 1;
    #10;
    send_packet = 0;

    while(!done) begin
      #10;
    end

    // Add more test cases as needed

    // End simulation
  end

endmodule