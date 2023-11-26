`include "../uart/uart_rx.v"
`include "../uart/uart_tx.v"
`include "../uart/baud_rate_generator.v"
`include "../uart-command-accumulator/uart_command_accumulator.v"
`include "../uart-command-enc-dec/host_uart_command_enc.v"
`include "host_specific_top_rx_from_host.v"
//`include "slave_command_to_spi.v"

module top_level (
  input wire clk,
  input wire reset,
  input wire host_uart_rx,
  input wire ble_uart_rx,
  input wire ble_side,
  output wire host_uart_tx,
  output wire ble_uart_tx,
  output o_SPI_Clk,
  input  i_SPI_MISO,
  output o_SPI_MOSI,
  output o_SPI_CS_n
);

  parameter BAUD_RATE = 9600;
  parameter CLOCK_FREQ = 50000000; //Target 50 MHz
  parameter CLKS_PER_HALF_BIT = 2;

  parameter ENCRYPT_ENABLE_DISABLE_RSP_ID = 16'h1;
  parameter READ_YAW_CMD_RSP_ID = 16'h2;

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
  reg [2:0] IMU_Command;
  reg Send_command_to_imu;
  
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
  wire[1:0] recieved_byte_count;
  wire IMU_ready_for_next_command;
  wire[7:0]recieved_byte_from_imu;
  wire valid_out_from_imu;
  wire host_rx_module_encrypt_decrypt_passthrough;

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

  // Encrypt/Decrypt module reg and wire
  reg[15:0] encrypt_decrypt_input;
  reg encrypt_decrypt_passthrough;
  reg encrypt_decrypt_start;
  wire[15:0] encrypt_decrypt_output;
  wire encrypt_decrypt_done;
  //

  //Local
  reg[263:0] local_received_spi_data_from_slave;
  reg[143:0] local_encoded_command_for_slave;
  reg[31:0] local_response_packet_slave_to_host;
  reg[143:0] local_encoded_response_slave_to_host;
  reg timeout_alarm;
  reg reset_timeout_alarm;
  integer timeout_count;
  reg[143:0] local_rx_encoded_packet;
  reg[143:0] local_tx_encoded_packet;
  reg[1023:0] local_host_ble_accumulated_data;
  reg[1024:0] local_host_encoded_command;
  reg soft_reset;
  reg[15:0] local_decrypted_data;
  reg[31:0] local_decrypted_assembled_data;
  reg[15:0] data_from_imu;

  parameter TIMEOUT = 4000000;

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
    .TIMEOUT(TIMEOUT)
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
    .TIMEOUT(TIMEOUT)
  ) host_ble_module_uart_accumulator(
    .clk(clk),
    .reset(reset),
    .input_data(ble_command_uart_output),
    .accumulate(ble_uart_rx_valid), // This might need to change. Unsure if driving it with valid will cause issues
    .ble_side(host_ble_accum_side_select),
    .soft_reset(soft_reset),
    .output_data(host_ble_accum_output_data),
    .output_data_size(host_ble_accum_output_data_size),
    .done(host_ble_accum_done),
    .error(host_ble_accum_error)
  );

  // Instantiate module to decode command from host and encode it into a command to send to the Slave
  host_specific_top_rx_from_host host_rx_top (
    .clk(clk),
    .reset(reset),
    .input_data(accumulated_input_from_host),
    .send_packet(decode_host_start),
    .encoded_output(encoded_command_for_slave),
    .encrypt_decrypt_passthrough(host_rx_module_encrypt_decrypt_passthrough),
    .error(host_command_decode_error),
    .done(host_command_decode_done)
  );

  // Module to use to get an encoded packet for the BLE module
  bluetooth_encoder host_ble_encoder_top (
    .input_data(ble_encoder_input_data),
    .command_select(ble_encoder_cmd),
    .start(ble_encoder_start),
    .clk(clk),
    .reset(reset),
    .output_data(ble_encoded_output),
    .done(ble_encoder_done)
  );

  // Module to use to encode a message to send back to the host PC
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

  // Module to use for encryption/decryption
  otp_encryption_decryption top_level_encryption_module (
    .input_data(encrypt_decrypt_input),
    .reset(reset),
    .passthrough(encrypt_decrypt_passthrough),
    .start(encrypt_decrypt_start),
    .output_data(encrypt_decrypt_output),
    .done(encrypt_decrypt_done)
  );

  // Comment out the slave side stuff
  /*
  // Instantiate from the encode dedcode until the spi
  slave_command_to_spi #(
    .CLKS_PER_HALF_BIT(CLKS_PER_HALF_BIT)
  ) slave_encode_to_spi (
    //inputs to encoder
    .clk(clk),
    .rst(reset),
    .transmit(Send_command_to_imu),
    .command(IMU_Command),

    //output from encoder
    .ready(IMU_ready_for_next_command),

    //outputs from the decoder
    .tx_byte(recieved_byte_from_imu),
    .valid_out(valid_out_from_imu),

    //Spi Interface
    .o_SPI_Clk(o_SPI_Clk),
    .i_SPI_MISO(i_SPI_MISO),
    .o_SPI_MOSI(o_SPI_MOSI),
    .o_SPI_CS_n(o_SPI_CS_n),
    .recieved_byte_count(recieved_byte_count)
  );
  */

  reg [7:0] state;
  reg [7:0] next_state;
  reg [8:0] go_back_state;

  integer transmit_index;
  integer rx_packet_transmit_index;
  integer host_command_transmit_index;
  integer valid_loop_count;

  always @(*) begin
    if(reset) begin
      // Reset variables
      transmit_index <= 7;
      rx_packet_transmit_index <= 7;
      host_command_transmit_index <= 7;
      valid_loop_count <= 0;
      reset_timeout_alarm <= 1'b1;
      soft_reset <= 1'b0;
      next_state <= 8'hFF;
      ble_uart_load_data <= 1'b0;
      go_back_state <= 8'h0;
      host_encoder_input_data <= 0;
      host_ble_accum_side_select <= 1'b1;
      encrypt_decrypt_passthrough <= 1'b1;
      encrypt_decrypt_input <= 16'h0;
      encrypt_decrypt_start <= 0;
      ble_uart_start_transmit <= 0;
      host_uart_start_transmit <= 0;
      ble_uart_load_data <= 0;
      host_uart_load_data <= 0;
      ble_encoder_start <= 0;
      host_encoder_start <= 0;
      decode_host_start <= 0;
      local_encoded_command_for_slave <= 0;
      local_encoded_response_slave_to_host <= 0;
      local_decrypted_data <= 0;
      local_host_ble_accumulated_data <= 0;
      local_host_encoded_command <= 0;
      local_host_ble_accumulated_data <= 0;
      local_tx_encoded_packet <= 0;
      local_received_spi_data_from_slave <= 0;
      data_from_imu <= 0;
    end else begin
      if(!ble_side) begin //Host side processing route
          case(state)

            8'h0: begin // 
              if(next_state == 8'h0) begin
                if(!accumulated_error) begin
                  if(accumulated_done) begin
                    next_state <= 8'h1; // Go to state to get bluetooth encoded packet
                    accumulated_input_from_host <= accumulated_output_data;
                    decode_host_start <= 1'b1; 
                    reset_timeout_alarm <= 1'b1;
                    transmit_index <= 7;
                    rx_packet_transmit_index <= 7;
                    host_command_transmit_index <= 7;

                    // Reset the local regs before each run
                    local_encoded_command_for_slave <= 0;
                    local_encoded_response_slave_to_host <= 0;
                    local_decrypted_data <= 0;
                    local_host_ble_accumulated_data <= 0;
                    local_host_encoded_command <= 0;
                    local_host_ble_accumulated_data <= 0;
                    local_tx_encoded_packet <= 0;
                    local_received_spi_data_from_slave <= 0;
                    valid_loop_count <= 0;
                  end else begin
                    next_state <= next_state;
                  end
                end else begin
                  next_state <= next_state;
                end
              end else begin
                next_state <= next_state;
              end
            end

            8'h1: begin // Get bluetooth encoded packet state
              if(next_state == 8'h1) begin
                reset_timeout_alarm <= 1'b0;
                decode_host_start <= 1'b0;
                if(host_command_decode_done) begin
                  if(!host_command_decode_error) begin
                    local_encoded_command_for_slave <= encoded_command_for_slave;
                    encrypt_decrypt_passthrough <= host_rx_module_encrypt_decrypt_passthrough;
                    next_state <= 8'h2; // uart load state
                  end else begin
                    soft_reset <= 1'b1;
                    next_state <= 8'hFC; // Go back to inital state
                  end
                end else begin
                  next_state <= next_state;
                end
              end else begin
                next_state <= next_state;
              end
            end

            8'h2: begin // Load state
              if(next_state == 8'h2) begin
                ble_uart_start_transmit <= 1'b0;
                if(ble_uart_tx_done) begin
                  ble_uart_tx_data <= local_encoded_command_for_slave[transmit_index -: 8];
                  ble_uart_load_data <= 1'b1;
                  next_state <= 8'h3;
                end else begin
                  next_state <= next_state;
                end
              end else begin
                next_state <= next_state;
              end
            end

            8'h3: begin // Transmit State
              if(next_state == 8'h3) begin
                  ble_uart_load_data <= 1'b0; // Signal that we are done loading data
                  ble_uart_start_transmit <= 1'b1; // Tell the uart module to send the data along
                  if(transmit_index >= 143) begin // If we have transmitted everything
                    // Move to final state
                    soft_reset <= 1'b1;
                    next_state <= 8'hFC; // Done so go back to initial
                  end else begin // if we haven't transmitted everything go to a state
                    transmit_index <= transmit_index + 8;
                    next_state <= 8'h2;
                  end
              end else begin
                next_state <= next_state;
              end
            end

            8'hFC: begin
              if(next_state == 8'hFC) begin
                  soft_reset <= 1'b0;
                  next_state <= 8'h0;
                  host_uart_start_transmit <= 1'b0; // Doing this for when we get here from state d
              end else begin
                next_state <= next_state;
              end
            end

            8'hFE: begin // A Delay state
              if(next_state == 8'hFE) begin
                next_state <= go_back_state;
              end else begin
                next_state <= next_state;
              end
            end

            8'hFF: begin // This is just a state to help us come out of a hard reset
              if(next_state == 8'hFF) begin
                  soft_reset <= 1'b1;
                  next_state <= 8'hFC; // make sure this points to end state
              end else begin
                next_state <= next_state;
              end
            end

            default: begin
              next_state <= next_state;
            end
          endcase
      end else begin// Add processing for slave side here
          // Don't do anythng here for now.
      end
    end
  end

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      state <= 8'h00;
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
      if(!ble_side) begin
        if(state == 8'h6 || state == 8'h7 || state == 8'h8) begin // When in RX waiting state start counting
          if(timeout_count > TIMEOUT) begin
            timeout_alarm <= 1'b1;
          end else begin
            timeout_count <= timeout_count + 1;
          end
        end
      end else begin
        if(state == 8'h8) begin // When waiting for SPI response
          if(timeout_count > TIMEOUT) begin
            timeout_alarm <= 1'b1;
          end else begin
            timeout_count <= timeout_count + 1;
          end
        end
      end
    end
  end

endmodule
