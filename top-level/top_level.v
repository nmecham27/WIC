`include "../uart/uart_rx.v"
`include "../uart/uart_tx.v"
`include "../uart/baud_rate_generator.v"
`include "../uart-command-accumulator/uart_command_accumulator.v"

module top_level (
  input wire clk,
  input wire reset,
  input wire host_uart_rx,
  input wire ble_uart_rx,
  input wire spi_miso,
  input wire ble_side,
  output reg host_uart_tx,
  output reg ble_uart_tx,
  output reg spi_mosi
);

  parameter BAUD_RATE = 9600;
  parameter CLOCK_FREQ = 38400000;

  //Output/Input
  wire baud_clk;

  //Inputs
  reg[1023:0] accumulated_input_from_host;
  reg decode_host_start;
  reg host_uart_start_transmit;
  reg host_uart_load_data;
  reg[7:0] host_uart_tx_data;
  reg ble_uart_start_transmit;
  reg ble_uart_load_data;
  reg[7:0] ble_uart_tx_data;
  
  //Outputs
  wire[143:0] encoded_command_for_slave;
  wire host_command_decode_error;
  wire host_command_decode_done;
  wire[7:0] host_command_uart_output;
  wire host_uart_rx_valid;
  wire host_uart_tx_done;
  wire[7:0] ble_command_uart_output;
  wire ble_uart_rx_valid;
  wire ble_uart_tx_done;
  wire[1023:0] accumulated_output_data;
  wire[7:0] accumulated_output_data_size;
  wire accumulated_done;
  wire accumulated_error;

  // Instantiate baud_rate_generator module
  baud_rate_generator #(
    .BAUD_RATE(BAUD_RATE),
    .CLOCK_FREQ(CLOCK_FREQ)
  ) baud_gen (
    .clk(clk),
    .reset(reset),
    .baud_out(baud_clk)
  );

  // Instantiate uart_tx module to send to ble slave
  uart_tx ble_uart_tx_module (
    .clk(baud_clk),
    .reset(reset),
    .start_transmit(ble_uart_start_transmit),
    .data(ble_uart_tx_data),
    .load_data(ble_uart_load_data),
    .tx_data(ble_uart_tx),
    .tx_finish(ble_uart_tx_done)
  );

  // Instantiate uart_rx to receive from ble slave
  uart_rx #(
    .BAUD_RATE(BAUD_RATE),
    .CLOCK_FREQ(CLOCK_FREQ)
  ) ble_uart_rx_module (
    .clk(clk),
    .rst(reset),
    .rx(ble_uart_rx),
    .data(ble_command_uart_output),
    .valid(ble_uart_rx_valid)
  );

  // Instantiate uart_tx module to send to host (On ble side this is from the host module via BLE breakout board)
  uart_tx host_tx (
    .clk(baud_clk),
    .reset(reset),
    .start_transmit(host_uart_start_transmit),
    .data(host_uart_tx_data),
    .load_data(host_uart_load_data),
    .tx_data(host_uart_tx),
    .tx_finish(host_uart_tx_done)
  );

  // Instantiate uart_rx to receive from host (On Ble side this is from the host module) via ble break board
  uart_rx #(
    .BAUD_RATE(BAUD_RATE),
    .CLOCK_FREQ(CLOCK_FREQ)
  ) host_rx (
    .clk(clk),
    .rst(reset),
    .rx(host_uart_rx),
    .data(host_command_uart_output),
    .valid(host_uart_rx_valid)
  );

  // Instantiate a uart command accumulator module
  uart_command_accumulator #(
    .TIMEOUT(2500)
  ) uart_command_accumulator(
    .clk(clk),
    .reset(reset),
    .input_data(host_command_uart_output),
    .accumulate(host_uart_rx_valid), // This might need to change. Unsure if driving it with valid will cause issues
    .ble_side(ble_side),
    .output_data(accumulated_output_data),
    .output_data_size(accumulated_output_data_size),
    .done(accumulated_done),
    .error(accumulated_error)
  );

  // Instantiate module to decode command from host and encode it into a command to send to the Slave
  host_specific_top_rx_from_host (
    .clk(clk),
    .reset(reset),
    .input_data(accumulated_input_from_host),
    .send_packet(decode_host_start),
    .encoded_output(encoded_command_for_slave),
    .error(host_command_decode_error),
    .done(host_command_decode_done)
  );

  reg [3:0] state;
  reg [3:0] next_state;

  always @(posedge reset or posedge accumulated_done or state) begin
    if(reset) begin
      // Reset variables
    end else begin
      if(!ble_side) begin //Host side processing route
        if(!accumulated_error) begin // If no error found then that means we have a packet to process
          case(state)
            
            4'h0: begin
              if(next_state == 4'h0) begin
                next_state <= 4'h1;
                accumulated_input_from_host = accumulated_output_data;
                decode_host_start = 1'b1; 
              end else begin
                next_state <= next_state;
              end
            end

            4'h1: begin
              if(next_state == 4'h1) begin
                decode_host_start = 1'b0;
                // Now need to send the bluetooth encoded data out the uart targeted for the slave
              end else begin
                next_state <= next_state;
              end
            end

            default: begin
              next_state <= next_state;
            end
          endcase
        end
      end else begin
        // Add processing for slave side here
      end
    end
  end

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      state <= 4'b0000;
    end else begin
      state <= next_state;
    end
  end



endmodule