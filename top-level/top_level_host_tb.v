`include "../uart/imported_uart_tx.v"
`include "../uart/imported_uart_rx.v"
//`include "../uart/baud_rate_generator.v"

`timescale 1ns/1ps
module top_level_host_tb;

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
  parameter c_CLKS_PER_BIT    = 5208;

  /*
  // Instantiate baud_rate_generator module
  baud_rate_generator #(
    .BAUD_RATE(BAUD_RATE),
    .CLOCK_FREQ(CLOCK_FREQ)
  ) baud_gen (
    .clk(clk),
    .reset(reset),
    .baud_out(baud_clk)
  );
  */

  wire tx_active;

  // Instantiate uart_tx module
  uart_tx #(.CLKS_PER_BIT(c_CLKS_PER_BIT)) tx(
    .i_Clock(clk),
    .i_Tx_DV(start_transmit),
    .i_Tx_Byte(uart_tx),
    .o_Tx_Serial(host_uart_rx),
    .o_Tx_Done(tx_done),
    .o_Tx_Active(tx_active)
  );

  /*
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
  */

  // Instantiate uart_rx module
  uart_rx #(.CLKS_PER_BIT(c_CLKS_PER_BIT)) rx (
    .i_Clock(clk),
    .i_Rx_Serial(ble_uart_tx),
    .soft_reset(soft_reset),
    .o_Rx_Byte(ble_uart_rx_data),
    .o_Rx_DV(rx_valid)
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

  parameter ENCRYPT_ENABLE = 88'hEFBE0101FFFFFFFFFFFF01;
  parameter ENCRYPT_DISABLE = 88'hEFBE0001FFFFFFFFFFFF01;
  parameter ENCRYPT_BAD_FORMAT_TARGET = 72'h0001FFFFFF27FFFF01;
  parameter ENCRYPT_BAD_FORMAT_SIZE = 72'h0002FFFFFFFFFFFF01;
  parameter READ_YAW = 56'hFF27FF27FF2703;
  parameter INVALID_COMMAND = 56'hFF27FF27FF2705;
  parameter ENCRYPT_COMMAND_RSP_FROM_SLAVE = 48'h0D8000000001;
  integer index;

  // Clock generation
  always begin
    #10 clk = ~clk;
  end

  // Stimulus generation
  initial begin
    ble_side = 1'b0;
    clk = 0;
    index = 7;
    reset = 1'b1;
    start_transmit = 1'b0;
    #20 reset = 1'b0;

    #20;
    
    while(index <= 87) begin
      uart_tx = ENCRYPT_DISABLE[index -: 8];
      #20;
      start_transmit = 1'b1;
      #20;
      start_transmit = 1'b0;
      
      while(!tx_done) begin
        //$display("Waiting for tx_done");
        #20;
      end
      index = index + 8;
      #20;
    end

    $display("Supposedly done sending byte");

    soft_reset = 1'b1;
    // Add delays and other stimulus as needed
    #100;

    soft_reset = 1'b0;

    while(!rx_valid) begin
      #20;
    end

    index = 7;
    $stop;
    #5000000;

    /*
    while(index <= 47) begin
      ble_uart_tx_data = ENCRYPT_COMMAND_RSP_FROM_SLAVE[index -: 8];
      $display("Sending uart packet %x", ble_uart_tx_data);
      #10;
      ble_load_data = 1'b1;
      #20;
      ble_load_data = 1'b0;
      #10;
      ble_start_transmit = 1'b1;
      #20;
      ble_start_transmit = 1'b0;
      #20;
      while(!ble_tx_done) begin
        #20;
      end
      index = index + 8;
      #20;
    end
    */
    // Continue adding stimulus and delays as needed
  end

  // Add your assertions and checks here

endmodule