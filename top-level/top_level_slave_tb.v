`include "../uart/uart_tx.v"
`include "../uart/baud_rate_generator.v"

`timescale 1ns/1ps
module top_level_slave_tb;

  // Inputs
  reg clk;
  reg reset;
  wire host_uart_rx;
  wire ble_uart_rx;
  reg ble_side;
  reg start_transmit;
  reg load_data;
  reg[7:0] uart_tx;
  reg i_SPI_MISO;

  // Outputs
  wire host_uart_tx;
  wire ble_uart_tx;
  wire tx_done;
  wire rx_valid;
  wire o_SPI_Clk;
  wire o_SPI_MOSI;
  wire o_SPI_CS_n;

  wire[7:0] ble_uart_rx_data;

  reg ble_start_transmit;
  reg[7:0] ble_uart_tx_data;
  reg ble_load_data;
  wire ble_tx_done;

  wire data_wire;
  wire baud_clk;
  reg soft_reset;

  parameter BAUD_RATE = 9600;
  parameter CLOCK_FREQ = 50000000;

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
    .tx_data(host_uart_rx),
    .tx_finish(tx_done)
  );

  // Instantiate uart_tx module
  uart_tx ble_tx (
    .clk(baud_clk),
    .reset(reset),
    .start_transmit(ble_start_transmit),
    .data(ble_uart_tx_data),
    .load_data(ble_load_data),
    .tx_data(ble_uart_rx),
    .tx_finish(ble_tx_done)
  );

  // Instantiate uart_rx module
  uart_rx #(
    .BAUD_RATE(BAUD_RATE),
    .CLOCK_FREQ(CLOCK_FREQ)
  ) rx (
    .clk(clk),
    .rst(reset),
    .rx(ble_uart_tx),
    .soft_reset(soft_reset),
    .data(ble_uart_rx_data),
    .valid(rx_valid)
  );

  // Instantiate the DUT
  top_level dut (
    .clk(clk),
    .reset(reset),
    .host_uart_rx(host_uart_rx),
    .ble_uart_rx(ble_uart_rx),
    .ble_side(ble_side),
    .host_uart_tx(host_uart_tx),
    .ble_uart_tx(ble_uart_tx),
    .o_SPI_Clk(o_SPI_Clk),
    .i_SPI_MISO(i_SPI_MISO),
    .o_SPI_MOSI(o_SPI_MOSI),
    .o_SPI_CS_n(o_SPI_CS_n)
  );

  parameter ENCRYPT_DISABLE = 40'h0D00000001;
  parameter ENCRYPT_ENABLE = 40'h0D00000002;
  parameter READ_YAW = 40'h0D00000003;
  integer index;

  // Clock generation
  always begin
    #10 clk = ~clk;
  end

  // Stimulus generation
  initial begin
    i_SPI_MISO = 1'b1;
    ble_side = 1'b1;
    clk = 0;
    index = 7;
    reset = 1'b1;
    #10 reset = 1'b0;
    
    #5000000;

    while(index <= 39) begin
      uart_tx = READ_YAW[index -: 8];
      #5;
      load_data = 1'b1;
      #5;
      load_data = 1'b0;
      #5;
      start_transmit = 1'b1;
      #5;
      start_transmit = 1'b0;
      #5;
      while(!tx_done) begin
        #20;
      end
      index = index + 8;
      #5;
    end
    
    // Continue adding stimulus and delays as needed
  end

  // Add your assertions and checks here

endmodule