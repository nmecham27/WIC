
`timescale 1ns / 1ps

module uart_command_accumulator_tb;

  // Inputs
  reg clk;
  reg reset;
  reg [7:0] input_data;
  reg accumulate;
  reg ble_side;
  reg soft_reset;

  // Outputs
  wire [1023:0] output_data;
  wire [7:0] output_data_size;
  wire done;
  wire error;

  // Local registers
  integer i;

  // Instantiate the module under test
  uart_command_accumulator #(
    .TIMEOUT(1026)
  ) dut (
    .clk(clk),
    .reset(reset),
    .input_data(input_data),
    .accumulate(accumulate),
    .ble_side(ble_side),
    .soft_reset(soft_reset),
    .output_data(output_data),
    .output_data_size(output_data_size),
    .done(done),
    .error(error)
  );

  // Clock generation
  always begin
    clk = 1'b0;
    #5;
    clk = 1'b1;
    #5;
  end

  // Reset initialization
  initial begin
    soft_reset = 0;
    ble_side = 1'b0;
    reset = 1'b1;
    #10;
    reset = 1'b0;
    #10;
    for(i = 0; i < 10; i = i + 1 ) begin
      input_data = 8'h27;
      accumulate = 1'b1;
      #60;
      accumulate = 1'b0;
      #5;
    end

    input_data = 8'hBE;
    accumulate = 1'b1;
    #60;
    accumulate = 1'b0;
    #5;
    input_data = 8'hEF;
    accumulate = 1'b1;
    #60;
    accumulate = 1'b0;
    #30;

    // Now reset and test a timeout
    reset = 1'b1;
    #10;
    reset = 1'b0;
    #10;
    input_data = 8'h1;
    for(i = 0; i < 10; i = i + 1 ) begin
      accumulate = 1'b1;
      #60;
      accumulate = 1'b0;
      #5;
      input_data = input_data + 8'h1;
    end

    #10600;
    reset = 1'b1;
    #10;
    reset = 1'b0;
    #10;

    //Simulate sending a bunch of bytes (MAX)
    input_data = 8'h1;
    for(i = 0; i < 128; i = i + 1 ) begin
      accumulate = 1'b1;
      #60;
      accumulate = 1'b0;
      #5;
      input_data = input_data + 8'h1;
    end
    #5;
    input_data = 8'hBE;
    #5
    accumulate = 1'b1;
    #60;
    accumulate = 1'b0;
    #5;
    input_data = 8'hEF;
    accumulate = 1'b1;
    #60;
    accumulate = 1'b0;
    #30;

    #10
    reset = 1'b1;
    #10;
    reset = 1'b0;
    #10;

    //Simulate sending too many of bytes
    input_data = 8'h1;
    for(i = 0; i < 129; i = i + 1 ) begin
      accumulate = 1'b1;
      #60;
      accumulate = 1'b0;
      #5;
      input_data = input_data + 8'h1;
    end

    #20;
    // Test the BLE side of the accumulate
    ble_side = 1'b1;
    #10;
    reset = 1'b1;
    #10;
    reset = 1'b0;
    #10;
    for(i = 0; i < 10; i = i + 1 ) begin
      input_data = 8'h27;
      accumulate = 1'b1;
      #60;
      accumulate = 1'b0;
      #5;
    end

    input_data = 8'hBE;
    #5;
    accumulate = 1'b1;
    #60;
    accumulate = 1'b0;
    #5;
    input_data = 8'hEF;
    accumulate = 1'b1;
    #60;
    accumulate = 1'b0;
    #30;
    input_data = 8'h0D;
    #5;
    accumulate = 1'b1;
    #60;
    accumulate = 1'b0;
    #5;

  end

endmodule