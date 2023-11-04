module top_level_uart #(
  parameter BAUD_RATE = 9600,
  parameter CLOCK_FREQ = 38400000
) (
  input wire clk,
  input wire reset,
  input wire[7:0] uart_tx,
  input wire start_transmit,
  input wire load_data,
  output wire[7:0] uart_rx,
  //output wire baud_clk,
  output wire valid,
  output wire tx_done
);

  wire data_wire;
  wire baud_clk;

  // Instantiate baud_rate_generator module
  baud_rate_generator #(
    .BAUD_RATE(BAUD_RATE),
    .CLOCK_FREQ(CLOCK_FREQ)
  ) baud_gen (
    .clk(clk),
    .reset(reset),
    .baud_out(baud_clk)
  );

  // Instantiate uart_tx module
  uart_tx tx (
    .clk(baud_clk),
    .reset(reset),
    .start_transmit(start_transmit),
    .data(uart_tx),
    .load_data(load_data),
    .tx_data(data_wire),
    .tx_finish(tx_done)
  );

  // Instantiate uart_rx module
  uart_rx #(
    .BAUD_RATE(BAUD_RATE),
    .CLOCK_FREQ(CLOCK_FREQ)
  ) rx (
    .clk(clk),
    .rst(reset),
    .rx(data_wire),
    .data(uart_rx),
    .valid(valid)
  );

endmodule