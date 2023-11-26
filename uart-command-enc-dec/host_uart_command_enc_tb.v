
`timescale 1ns/1ps
module host_uart_command_enc_tb;

  // Inputs
  reg clk;
  reg reset;
  reg[263:0] input_data;
  reg start;
  reg[15:0] cmd_select;
  reg suc_or_fail_status;

  // Outputs
  wire[255:0] output_data;
  wire done;
  wire error;

  // Instantiate the module under test
  host_uart_command_enc dut (
    .clk(clk),
    .reset(reset),
    .input_data(input_data),
    .start(start),
    .cmd_select(cmd_select),
    .suc_or_fail_status(suc_or_fail_status),
    .output_data(output_data),
    .done(done),
    .error(error)
  );

  parameter ENCRYPT_ENABLE_RSP_ID = 16'h1;
  parameter READ_YAW_RSP_ID = 16'h2;
  parameter INVALID_COMMAND_RSP_ID = 16'h4;

  // Clock generation
  always #5 clk = ~clk;

  // Test stimulus
  initial begin
    // Initialize inputs
    clk = 0;
    reset = 1;
    input_data = 0;
    suc_or_fail_status = 0;
    cmd_select = 0;
    start = 0;

    // Wait for reset to deassert
    #10 reset = 0;
    
    cmd_select = ENCRYPT_ENABLE_RSP_ID;
    suc_or_fail_status = 1;
    #5;
    start = 1;
    #10;
    start = 0;

    while(!done) begin
      #10;
    end

    #20;
    input_data = 32'h04030201;
    cmd_select = READ_YAW_RSP_ID;
    suc_or_fail_status = 1;
    #5;
    start = 1;
    #10;
    start = 0;

    while(!done) begin
      #10;
    end

    #20;
    input_data = 32'h04030201;
    cmd_select = READ_YAW_RSP_ID;
    suc_or_fail_status = 0;
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

    #20;
    cmd_select = INVALID_COMMAND_RSP_ID;
    input_data = 0;
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