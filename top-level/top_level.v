`include "../uart/uart_rx.v"
`include "../uart/uart_tx.v"
`include "../uart/baud_rate_generator.v"
`include "../uart-command-accumulator/uart_command_accumulator.v"
`include "../uart-command-enc-dec/host_uart_command_enc.v"

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
  reg[31:0] ble_encoder_input_data;
  reg[3:0] ble_encoder_cmd;
  reg ble_encoder_start;
  
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
  wire ble_encoder_done;
  wire[143:0] ble_encoded_output;

  // Host ble module accumulate reg and wire
  reg[7:0] host_ble_accum_output;
  reg host_ble_accum;
  reg host_ble_accum_side_select;
  wire[1023:0] host_ble_accum_output_data;
  wire[7:0] host_ble_accum_output_data_size;
  wire host_ble_accum_done;
  wire host_ble_accum_error;
  //

  // Host command encoder reg and wire
  reg[263:0] host_encoder_input_data;
  reg host_encoder_start;
  reg[16:0] host_encoder_cmd_select;
  reg host_encoder_suc_or_fail;
  wire[1024:0] host_encoder_output_data;
  wire host_encoder_done;
  wire host_encoder_error;
  //

  //Local
  reg[143:0] local_encoded_command_for_slave;
  reg timeout_alarm;
  reg reset_timeout_alarm;
  integer timeout_count;
  reg[143:0] local_rx_encoded_packet;
  reg[1023:0] local_host_ble_accumulated_data;
  reg[1024:0] local_host_encoded_command;
  reg soft_reset;

  parameter TIMEOUT = 1000;

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
    .soft_reset(soft_reset),
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
    .soft_reset(soft_reset),
    .data(host_command_uart_output),
    .valid(host_uart_rx_valid)
  );

  // Instantiate a uart command accumulator module. This will return the accumulated data when it sees 0xBE then 0xEF.
  uart_command_accumulator #(
    .TIMEOUT(2500)
  ) uart_command_accumulator(
    .clk(clk),
    .reset(reset),
    .input_data(host_command_uart_output),
    .accumulate(host_uart_rx_valid),
    .ble_side(ble_side),
    .soft_reset(soft_reset),
    .output_data(accumulated_output_data),
    .output_data_size(accumulated_output_data_size),
    .done(accumulated_done),
    .error(accumulated_error)
  );

  // Instantiate a ble module uart accumulator module. This will return the accumulated data when it sees "\r" or 0x0D.
  uart_command_accumulator #(
    .TIMEOUT(2500)
  ) host_ble_module_uart_accumulator(
    .clk(clk),
    .reset(reset),
    .input_data(host_ble_accum_output),
    .accumulate(ble_uart_rx_valid), // This might need to change. Unsure if driving it with valid will cause issues
    .ble_side(host_ble_accum_side_select),
    .soft_reset(soft_reset),
    .output_data(host_ble_accum_output_data),
    .output_data_size(host_ble_accum_output_data_size),
    .done(host_ble_accum_done),
    .error(host_ble_accum_error)
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

  bluetooth_encoder ble_encoder (
    .input_data(ble_encoder_input_data),
    .command_select(ble_encoder_cmd),
    .start(ble_encoder_start),
    .clk(clk),
    .reset(reset),
    .output_data(ble_encoded_output),
    .done(ble_encoder_done)
  );

  host_uart_command_enc host_command_encoder (
    .clk(clk),
    .reset(reset),
    .input_data(host_encoder_input_data),
    .start(host_encoder_start),
    .cmd_select(host_encoder_cmd_select),
    .suc_or_fail_status(host_encoder_suc_or_fail),
    .output_data(host_encoder_output_data),
    .done(host_encoder_done),
    .error(host_encoder_error)
  );

  reg [3:0] state;
  reg [3:0] next_state;

  integer transmit_index;
  integer rx_packet_transmit_index;
  integer host_command_transmit_index;
  integer valid_loop_count;

  always @(posedge reset or posedge accumulated_done or state or posedge timeout_alarm) begin
    if(reset) begin
      // Reset variables
      transmit_index <= 7;
      rx_packet_transmit_index <= 7;
      host_command_transmit_index <= 7;
      valid_loop_count <= 0;
      reset_timeout_alarm <= 1'b1;
      soft_reset <= 1'b0;
    end else begin
      if(!ble_side) begin //Host side processing route
        if(!accumulated_error) begin // If no error found then that means we have a packet to process
          case(state)
            
            4'h0: begin // 
              if(next_state == 4'h0) begin
                if(accumulated_done) begin
                  next_state <= 4'h1; // Go to state to get bluetooth encoded packet
                  accumulated_input_from_host = accumulated_output_data;
                  decode_host_start = 1'b1; 
                  reset_timeout_alarm <= 1'b1;
                  transmit_index <= 7;
                  rx_packet_transmit_index <= 7;
                  host_command_transmit_index <= 7;
                end else begin
                  next_state <= next_state;
                end
              end else begin
                next_state <= next_state;
              end
            end

            4'h1: begin // Get bluetooth encoded packet state
              if(next_state == 4'h1) begin
                reset_timeout_alarm <= 1'b0;
                decode_host_start = 1'b0;
                if(host_command_decode_done) begin
                  if(!host_command_decode_error) begin
                    local_encoded_command_for_slave <= encoded_command_for_slave;
                    next_state <= 4'h2; // uart load state
                  end else begin
                    soft_reset <= 1'b1;
                    next_state <= 4'he; // Go back to inital state
                  end
                end else begin
                  next_state <= next_state;
                end
              end else begin
                next_state <= next_state;
              end
            end

            4'h2: begin // Load state
              if(next_state == 4'h2) begin
                if(ble_uart_tx_done) begin
                  ble_uart_start_transmit = 1'b0;
                  ble_uart_tx_data <= local_encoded_command_for_slave[transmit_index -: 8];
                  ble_uart_load_data <= 1'b1;
                  next_state <= 4'h3;
                end else begin
                  next_state <= next_state;
                end
              end else begin
                next_state <= next_state;
              end
            end

            4'h3: begin // Transmit State
              if(next_state == 4'h3) begin
                  ble_uart_load_data = 1'b0; // Signal that we are done loading data
                  ble_uart_start_transmit = 1'b1; // Tell the uart module to send the data along
                  if(transmit_index >= 143) begin // If we have transmitted everything
                    // Move to rx start state
                    next_state <= 4'h4;
                  end else begin // if we haven't transmitted everything go to a state
                    transmit_index = transmit_index + 8;
                    next_state <= 4'h2; //
                  end
              end else begin
                next_state <= next_state;
              end
            end

            4'h4: begin // RX start
              // continuously send AT+RX command to ble module
              // if we get something on the uart (uart RX valid high) then move on
              // or we could timeout.
              if(next_state == 4'h4) begin
                  ble_uart_start_transmit = 1'b0; // Tell the uart module to send the data along

                  // Get the AT command for rx
                  ble_encoder_input_data = 32'h0;
                  ble_encoder_cmd = 4'h2; // We are requesting a AT+BLEUARTRX packet
                  ble_encoder_start = 1'b1;
                  next_state <= 4'h5;

              end else begin
                next_state <= next_state;
              end
            end

            4'h5: begin // RX start
              if(next_state == 4'h5) begin
                  ble_encoder_start <= 1'b0;
                  if(ble_encoder_done) begin
                    local_rx_encoded_packet <= ble_encoded_output;
                    next_state <= 4'h6;
                  end else begin
                    next_state <= next_state;
                  end
              end else begin
                next_state <= next_state;
              end
            end

            4'h6: begin // Load uart
              if(next_state == 4'h6) begin
                if(!timeout_alarm) begin
                  if(ble_uart_tx_done) begin
                    ble_uart_start_transmit = 1'b0;
                    ble_uart_tx_data <= local_rx_encoded_packet[rx_packet_transmit_index -: 8];
                    ble_uart_load_data <= 1'b1;
                    next_state <= 4'h7;
                  end else begin
                    next_state <= next_state;
                  end
                end else begin
                  soft_reset <= 1'b1;
                  next_state <= 4'he;
                end
              end else begin
                next_state <= next_state;
              end
            end

            4'h7: begin // Transmit State
              if(next_state == 4'h7) begin
                if(!timeout_alarm) begin
                  ble_uart_load_data = 1'b0; // Signal that we are done loading data
                  ble_uart_start_transmit = 1'b1; // Tell the uart module to send the data along
                  if(rx_packet_transmit_index >= 143) begin // If we have transmitted everything
                    // Move to rx start state
                    next_state <= 4'h8; // Move to state to check uart valid
                  end else begin // if we haven't transmitted everything go to a state
                    rx_packet_transmit_index = rx_packet_transmit_index + 8;
                    next_state <= 4'h6; //
                  end
                end else begin
                  soft_reset <= 1'b1;
                  next_state <= 4'he;
                end
              end else begin
                next_state <= next_state;
              end
            end

            4'h8: begin // Check UART valid
              if(next_state == 4'h8) begin
                if(!timeout_alarm) begin
                  if(ble_uart_rx_valid) begin
                    //Move to packet accumulate state
                    next_state <= 4'h9;
                  end else if(valid_loop_count < 60) begin
                    valid_loop_count = valid_loop_count + 1;
                    next_state <= 4'h8; // Look out for this could cause issue with not rerunning block
                  end else begin
                    rx_packet_transmit_index <= 7;
                    next_state <= 4'h6;
                  end
                end else begin
                  soft_reset <= 1'b1;
                  next_state <= 4'he; // Go back to initial state since timeout
                end
              end else begin
                next_state <= next_state;
              end
            end

            4'h9: begin
              if(next_state == 4'h9) begin
                if(host_ble_accum_done) begin
                  if(!host_ble_accum_error) begin
                    local_host_ble_accumulated_data <= host_ble_accum_output_data;
                    next_state <= 4'ha;
                  end else begin
                    soft_reset <= 1'b1;
                    next_state <= 4'he;
                  end
                end else begin
                  next_state <= next_state;
                end
              end else begin
                next_state <= next_state;
              end
            end

            4'ha: begin // Load the host command encoder
              if(next_state == 4'ha) begin
                // Encode the packet for sending back to host
                host_encoder_input_data = local_host_ble_accumulated_data[271:8];
                host_encoder_cmd_select = local_host_ble_accumulated_data[7:0];
                host_encoder_suc_or_fail = local_host_ble_accumulated_data[272];
                host_encoder_start = 1'b1;
                next_state <= 4'hb;
              end else begin
                next_state <= next_state;
              end
            end

            4'hb: begin // Load the host command encoder
              if(next_state == 4'hb) begin
                // Save the encoded command
                if(host_encoder_done) begin
                  if(!host_encoder_error) begin
                    local_host_encoded_command <= host_encoder_output_data;
                    next_state <= 4'hc; // Move to transmit this back to the host
                  end else begin
                    soft_reset <= 1'b1;
                    next_state <= 4'he;
                  end
                end else begin
                  next_state <= next_state;
                end
                next_state <= 4'hb;
              end else begin
                next_state <= next_state;
              end
            end

            4'hc: begin // Load state for sending command back to host
              if(next_state == 4'hc) begin
                if(host_uart_tx_done) begin
                  host_uart_start_transmit = 1'b0;
                  host_uart_tx_data <= local_host_encoded_command[host_command_transmit_index -: 8];
                  host_uart_load_data <= 1'b1;
                  next_state <= 4'hd;
                end else begin
                  next_state <= next_state;
                end
              end else begin
                next_state <= next_state;
              end
            end

            4'hd: begin // Transmit State
              if(next_state == 4'hd) begin
                  host_uart_load_data = 1'b0; // Signal that we are done loading data
                  host_uart_start_transmit = 1'b1; // Tell the uart module to send the data along
                  if(host_command_transmit_index >= 1023) begin // If we have transmitted everything
                    // Move to rx start state
                    soft_reset <= 1'b1;
                    next_state <= 4'he; // Done so go back to initial
                  end else begin // if we haven't transmitted everything go to a state
                    host_command_transmit_index = host_command_transmit_index + 8;
                    next_state <= 4'h2; //
                  end
              end else begin
                next_state <= next_state;
              end
            end

            4'he: begin
              if(next_state == 4'he) begin
                  soft_reset <= 1'b0;
                  next_state <= 4'h0;
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

  // This is our alarm counter
  always @(posedge clk or posedge reset or posedge reset_timeout_alarm) begin
    if(reset || reset_timeout_alarm) begin
      timeout_count <= 0;
      timeout_alarm <= 1'b0;
    end else begin
      if(state == 4'h6 || state == 4'h7 || state == 4'h8) begin // When in RX waiting state start counting
        if(timeout_count > TIMEOUT) begin
          timeout_alarm <= 1'b1;
        end else begin
          timeout_count <= timeout_count + 1;
        end
      end
    end
  end

endmodule