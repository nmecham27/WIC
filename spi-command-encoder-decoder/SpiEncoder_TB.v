
module spi_encoder_tb;

  // Inputs
  reg clk;
  reg rst_n;
  reg transmit;
  reg transmitRecieved;
  reg [2:0] command;

  // Outputs
  wire mosi;
  wire [7:0] addressToTransfer;
  wire [1:0] i_TX_Count;
  wire transmissionSent;

  // Instantiate the spi_encoder module
  spi_encoder dut (
    .clk(clk),
    .rst_n(rst_n),
    .transmit(transmit),
    .transmitRecieved(transmitRecieved),
    .command(command),
    .mosi(mosi),
    .addressToTransfer(addressToTransfer),
    .i_TX_Count(i_TX_Count),
    .transmissionSent(transmissionSent)
  );

  // Clock generation
  always begin
    #5 clk = 1;
    #5 clk = 0;
  end

  // Reset generation
  initial begin
    rst_n = 0;
    #10 rst_n = 1;
  end

  // Test stimulus
  initial begin
    // Wait for reset to complete
    @(posedge clk);
    @(posedge clk);

    // Test case 1: Transmit command GETROLLANGULAR
    transmit = 1;
    command = 3'b000;
    @(posedge clk);
    @(posedge clk);
    transmit = 0;
    @(posedge clk);
    // Verify outputs here
    if(addressToTransfer == 8'b10100100)begin
      transmitRecieved = 1;
    end

    if(transmissionSent == 1'b1)begin
      transmitRecieved = 0;
      @(posedge clk);
    end else begin 
      @(posedge clk);
    end

    // Test case 2: Transmit command GETPITCHLINEAR
    transmit = 1;
    command = 3'b011;
    @(posedge clk);
    @(posedge clk);
    transmit = 0;
    @(posedge clk);
    // Verify outputs here
    if(addressToTransfer == 8'b10101000)begin
      transmitRecieved = 1;
    end

    if(transmissionSent == 1'b1)begin
      transmitRecieved = 0;
      @(posedge clk);
    end else begin 
      @(posedge clk);
    end

    // Add more test cases as needed

    // End simulation
    $finish;
  end

endmodule