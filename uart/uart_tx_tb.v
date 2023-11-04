module uart_tx_tb;

  reg clk;
  reg reset;
  reg start_transmit;
  reg [7:0] data;
  reg load_data;
  reg done;

  wire [3:0] state;
  wire [10:0] bit_count;
  wire tx_data;

  uart_tx dut (
    .clk(clk),
    .reset(reset),
    .start_transmit(start_transmit),
    .data(data),
    .load_data(load_data),
    .tx_data(tx_data),
    .tx_finish(done)
  );

  always begin
    #52 clk = ~clk; // 9600 Hz clock frequency
  end

  initial begin
    clk = 0;
    reset = 1;
    start_transmit = 0;
    data = 8'b00100111; // 0x27
    load_data = 0;

    #104 reset = 0; // Release reset after 2 clock cycles

    // Transmit data
    load_data = 1; // Assert load_data
    #1 load_data = 0; // Deassert load_data after 1 clock cycle
    #2 start_transmit = 1; // Set start_transmit to 1 after 2 clock cycles
    #1 start_transmit = 0; // Deassert start_transmit after 1 clock cycle
  end

endmodule