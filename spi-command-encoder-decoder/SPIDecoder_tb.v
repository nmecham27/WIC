
module spi_decoder_tb;

  // Parameters
  parameter MAX_BYTES_PER_CS = 2;

  // Inputs
  reg clk;
  reg rst_n;
  reg data_valid;
  reg [$clog2(MAX_BYTES_PER_CS+1)-1:0] RX_Count;
  reg [7:0] rx_byte;

  // Outputs
  wire [7:0] tx_byte;
  wire valid_out;

  // Instantiate the spi_decoder module
  spi_decoder #(
    .MAX_BYTES_PER_CS(MAX_BYTES_PER_CS)
  ) dut (
    .clk(clk),
    .rst_n(rst_n),
    .data_valid(data_valid),
    .RX_Count(RX_Count),
    .rx_byte(rx_byte),
    .tx_byte(tx_byte),
    .valid_out(valid_out)
  );

  // Clock generation
  always begin
    clk = 0;
    #5;
    clk = 1;
    #5;
  end

  // Test case
  initial begin
    // Initialize inputs
    rst_n = 0;
    data_valid = 0;
    RX_Count = 0;
    rx_byte = 0;

    // Reset
    @(posedge clk)
    rst_n = 1;

    // Wait for reset to complete
    @(posedge clk)

    // Test case 1: Recieve 16 bits of data
    data_valid = 1;
    RX_Count = 2;
    rx_byte = 8'b10101010;
    @(posedge clk)
    data_valid = 0;
     @(posedge clk)
    data_valid = 1;
    rx_byte = 8'b01101010;
    @(posedge clk)
    data_valid = 0;
    @(posedge clk)
    @(posedge clk)
    @(posedge clk)
    // Test case 2: Recieve 16 bits of data again
    data_valid = 1;
    RX_Count = 2;
    rx_byte = 8'b10101010;
    @(posedge clk)
    data_valid = 0;
     @(posedge clk)
    data_valid = 1;
    rx_byte = 8'b01101010;
    @(posedge clk)
    data_valid = 0;
    @(posedge clk)

    // End simulation
    $finish;
  end

endmodule