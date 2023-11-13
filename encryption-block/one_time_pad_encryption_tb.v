`timescale 1ns/1ps
module otp_encryption_decryption_tb;
  reg [15:0] input_data;
  wire [15:0] output_data;
  reg rst;
  reg passthrough;
  reg start;
  wire done;

  otp_encryption_decryption dut (
    .input_data(input_data),
    .reset(rst),
    .passthrough(passthrough),
    .start(start),
    .output_data(output_data),
    .done(done)
  );

  reg [7:0] output_holder;

  initial begin
    rst = 1;
    #50;
    rst = 0;
    #10;
    
    start = 1'b0;
    passthrough = 1'b0;
    input_data = 16'h2733;
    start = 1'b1;
    #5; // We need to hold start high for a small amount of time
    start = 1'b0;

    while(!done) begin
      #100;
    end

    //output_holder = output_data;

    $display("Data to encrypt: %h", input_data);
    $display("Encrypted Data: %h", output_data);

    #10;

    input_data = output_data;
    start = 1'b1;
    #5; // We need to hold start high for a small amount of time
    start = 1'b0;
    
    while(!done) begin
      #1;
    end

    $display("Decrypted Data: %h", output_data);

    #50;

    input_data = 16'h3327;
    start = 1'b1;
    #5; // We need to hold start high for a small amount of time
    start = 1'b0;
    
    while(!done) begin
      #1;
    end

    $display("Data to encrypt: %h", input_data);
    $display("Encrypted Data: %h", output_data);

    #10;

    input_data = output_data;
    start = 1'b1;
    #5; // We need to hold start high for a small amount of time
    start = 1'b0;
    
    while(!done) begin
      #1;
    end

    $display("Decrypted Data: %h", output_data);

    #10;

    // Test a value of 0x1
    #50;

    input_data = 16'h1;
    start = 1'b1;
    #5; // We need to hold start high for a small amount of time
    start = 1'b0;
    
    while(!done) begin
      #1;
    end

    $display("Data to encrypt: %h", input_data);
    $display("Encrypted Data: %h", output_data);

    #10;

    input_data = output_data;
    start = 1'b1;
    #5; // We need to hold start high for a small amount of time
    start = 1'b0;
    
    while(!done) begin
      #1;
    end

    $display("Decrypted Data: %h", output_data);

    #10;

    // Test a plain text value
    passthrough = 1'b1;
    input_data = 16'hDEAD;
    start = 1'b1;
    #5; // We need to hold start high for a small amount of time
    start = 1'b0;
    
    while(!done) begin
      #1;
    end

    $display("Data to encrypt: %h", input_data);
    $display("Encrypted Data: %h", output_data);

    #10;

    input_data = output_data;
    start = 1'b1;
    #5; // We need to hold start high for a small amount of time
    start = 1'b0;
    
    while(!done) begin
      #1;
    end

    $display("Decrypted Data: %h", output_data);
  end
endmodule