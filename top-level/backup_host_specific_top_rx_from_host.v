module host_specific_top_rx_from_host.v (
  input wire clk,
  input wire reset,
  input wire[1023:0] input_data,
  input wire send_packet,
  output reg[143:0] encoded_output,
  output reg error
);

  // Inputs
  reg command_dec_start;
  reg[15:0] encrypt_input_two_bytes;
  reg encryption_passthrough;
  reg encryption_start;
  reg[31:0] ble_input_data;
  reg[3:0] ble_cmd;
  reg ble_enc_start;
  reg start_uart_transmit;
  reg[7:0] uart_input_data;
  reg uart_load_data;


  // Outputs
  reg[255:0] decoded_output_data;
  reg[15:0] decoded_cmd;
  reg decode_done;
  reg decode_error;
  reg[15:0] encrypted_output_two_bytes;
  reg encrypt_done;
  reg[143:0] ble_output_data;
  reg ble_enc_done;
  reg uart_finish;

  // Local variables
  reg [3:0] state;
  reg [3:0] next_state;
  reg encryptionEnabled;
  integer i;

  host_uart_command_dec command_decoder (
    .clk(clk),
    .reset(reset),
    .input_data(input_data),
    .start(command_dec_start),
    .output_data(decoded_output_data),
    .done(decode_done),
    .error(decode_error),
    .cmd_select(decoded_cmd)
  );

  otp_encryption_decryption encryption_module (
    .input_data(encrypt_input_two_bytes),
    .reset(reset),
    .passthrough(encryption_passthrough),
    .start(encryption_start),
    .output_data(encrypted_output_two_bytes),
    .done(encrypt_done)
  );

  bluetooth_encoder ble_encoder (
    .input_data(ble_input_data),
    .command_select(ble_cmd),
    .start(ble_enc_start),
    .clk(clk),
    .reset(reset),
    .output_data(ble_output_data),
    .done(ble_enc_done)
  );

  //uart_tx uart_tx_module (
  //  .clk(clk),
  //  .reset(reset),
  //  .start_transmit(start_uart_transmit),
  //  .data(uart_input_data),
  //  .load_data(uart_load_data),
  //  .tx_data(uart_output),
  //  .tx_finish(uart_finish)
  //);

  always @(posedge clk or posedge reset) begin
    if(reset) begin
      state <= 4'h0;
    end else begin
      state <= next_state;
    end
  end

  always @(posedge reset or posedge send_packet or state) begin
    if(reset) begin
      command_dec_start <= 1'b0;
      encrypt_input_byte <= 8'h0;
      encryption_passthrough <= 1'b1;
      encryption_start <= 1'b0;
      ble_input_data <= 32'h0;
      ble_cmd <= 4'h0;
      ble_enc_start <= 1'b0;
      error <= 1'b0;
      i <= 0;
    end else begin
      case(state)

        4'h0: begin
          if(send_packet) begin
            i <= 0;
            error <= 1'b0;
            command_dec_start <= 1'b1;
            next_state <= 4'h1; // Move to the decrypt command state
          end
        end

        4'h1: begin
          if(next_state == 4'h1) begin
            command_dec_start <= 1'b0;
            if(decode_done) begin
              if(!decode_error) begin

                case(decoded_cmd)

                  16'h1: begin // If the command was encryption enable
                    next_state <= 4'h2; // encrypt state
                  end

                  16'h2: begin // If the command was encryption disable
                    next_state <= 4'h2; // encrypt state
                  end

                  16'h3: begin // If the command was encryption enable
                    next_state <= 4'h2; // encrypt state
                  end

                endcase

              end else begin
                error <= 1'b1; // Set the error flag
                next_state <= 4'h0; // Go back to initial state
              end
            end else begin
              next_state <= next_state;
            end
          end else begin
            next_state <= next_state;
          end
        end

        4'h2: begin //Encrypt state
          if(next_state == 4'h2) begin
            encrypt_input_two_bytes <= decoded_cmd;
            encryption_start <= 1'b1;
            next_state <= 4'h3;
          end else begin
            next_state <= next_state;
          end
        end

        4'h3: begin // Encode state
          if(next_state == 4'h3) begin
            if(encrypt_done) begin
              ble_input_data <= encrypted_output_two_bytes;
              ble_cmd <= 4'h1;
              ble_enc_start <= 1'b1;
              next_state <= 4'h4;
            end else begin
              next_state <= next_state;
            end
          end else begin
            next_state <= next_state;
          end
        end

        4'h4: begin // Send ble state
          if(next_state == 4'h4) begin
            if(ble_enc_done) begin
              for(i = 7; i < 145; i = i + 8) begin

              end
            end else begin
              next_state <= next_state;
            end           
          end else begin
            next_state <= next_state;
          end
        end

        4'h5: begin // Send close byte state
          if(next_state == 4'h5) begin
            
          end else begin
            next_state <= next_state;
          end
        end

        4'h6: begin // Set encrypt high or low
          if(next_state == 4'h6) begin
            
          end else begin
            next_state <= next_state;
          end
        end

        4'h7: begin // Send RX
          if(next_state == 4'h7) begin
            
          end else begin
            next_state <= next_state;
          end
        end

        4'h8: begin // Decrypt
          if(next_state == 4'h8) begin
            
          end else begin
            next_state <= next_state;
          end
        end

        4'h9: begin // Encode host command
          if(next_state == 4'h1) begin
            
          end else begin
            next_state <= next_state;
          end
        end

        default: begin
          error <= 1'b1;
          next_state <= 4'h0;
        end

      endcase
    end
  end

endmodule