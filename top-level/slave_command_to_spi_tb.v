
module slave_command_to_spi_tb;

  // Inputs
  reg clk;
  reg rst;
  reg transmit;
  reg [2:0] command;
  //Weird input works on the spi_clk
  reg i_SPI_MISO;

  // Outputs
  wire ready;
  wire [7:0] tx_byte;
  wire valid_out;
  wire o_SPI_Clk;
  wire o_SPI_MOSI;
  wire o_SPI_CS_n;
  wire [1:0]recieved_byte_count;

  // Instantiate the module under test
  slave_command_to_spi dut (
    .clk(clk),
    .rst(rst),
    .transmit(transmit),
    .command(command),
    .ready(ready),
    .tx_byte(tx_byte),
    .valid_out(valid_out),
    .o_SPI_Clk(o_SPI_Clk),
    .i_SPI_MISO(i_SPI_MISO),
    .o_SPI_MOSI(o_SPI_MOSI),
    .o_SPI_CS_n(o_SPI_CS_n),
    .recieved_byte_count(recieved_byte_count)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Initial stimulus
  initial begin
    clk = 0;
    rst = 1;
    transmit = 0;
    command = 0;
    i_SPI_MISO = 1;

    #10 rst = 0;

    // Send command
    transmit = 1;
    command = 3;

    #10 transmit = 0;

    repeat (8) @(posedge o_SPI_Clk)begin
      i_SPI_MISO = ~ i_SPI_MISO;
    end
    // Wait for ready signal
    repeat (10) @(posedge clk);
    
    // Check outputs
    $display("tx_byte = %h", tx_byte);
    $display("valid_out = %b", valid_out);
    $display("o_SPI_Clk = %b", o_SPI_Clk);
    $display("i_SPI_MISO = %b", i_SPI_MISO);
    $display("o_SPI_MOSI = %b", o_SPI_MOSI);
    $display("o_SPI_CS_n = %b", o_SPI_CS_n);

    repeat(100) @(posedge clk);
  end

endmodule