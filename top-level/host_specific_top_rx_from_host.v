`include "../encryption-block/one_time_pad_encryption.v"
`include "../uart-command-enc-dec/host_uart_command_dec.v"
`include "../bluetooth-encoder/bluetooth_encoder.v"

module host_specific_top_rx_from_host (
  input wire clk,
  input wire reset,
  input wire[1023:0] input_data,
  input wire send_packet,
  output reg[143:0] encoded_output,
  output reg error,
  output reg done
);

  // Inputs
  reg command_dec_start;
  reg[15:0] encrypt_input_two_bytes;
  reg encryption_passthrough;
  reg encryption_start;
  reg[31:0] ble_input_data;
  reg[3:0] ble_cmd;
  reg ble_enc_start;

  // Outputs
  wire[255:0] decoded_output_data;
  wire[15:0] decoded_cmd;
  wire decode_done;
  wire decode_error;
  wire[15:0] encrypted_output_two_bytes;
  wire encrypt_done;
  wire ble_enc_done;
  wire[143:0] ble_enc_output;

  // Local variables
  reg [3:0] state;
  reg [3:0] next_state;

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
    .output_data(ble_enc_output),
    .done(ble_enc_done)
  );

  always @(posedge clk or posedge reset) begin
    if(reset) begin
      state <= 4'h0;
    end else begin
      state <= next_state;
    end
  end

  always @(posedge reset or posedge send_packet or state or posedge decode_done or posedge ble_enc_done or posedge encrypt_done) begin
    if(reset) begin
      command_dec_start <= 1'b0;
      encryption_passthrough <= 1'b1;
      encryption_start <= 1'b0;
      ble_input_data <= 32'h0;
      ble_cmd <= 4'h0;
      ble_enc_start <= 1'b0;
      error <= 1'b0;
      done <= 1'b1;
      encoded_output <= 144'h0;
      next_state <= 4'h0;
    end else begin
      case(state)

        4'h0: begin
          if(send_packet) begin
            done <= 1'b0;
            error <= 1'b0;
            command_dec_start <= 1'b1;
            next_state <= 4'h1; // Move to the decrypt command state
          end else begin
            done <= 1'b1;
            next_state <= 4'h0;
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
            encrypt_input_two_bytes = decoded_cmd;
            encryption_start = 1'b1;
            next_state <= 4'h3;
          end else begin
            next_state <= next_state;
          end
        end

        4'h3: begin // Encode state
          if(next_state == 4'h3) begin
            encryption_start <= 1'b0;
            if(encrypt_done) begin
              ble_input_data = encrypted_output_two_bytes;
              ble_cmd = 4'h1; // This is a TX command
              ble_enc_start = 1'b1;
              next_state <= 4'h4;
            end else begin
              next_state <= next_state;
            end
          end else begin
            next_state <= next_state;
          end
        end

        4'h4: begin // Save the encoded output
          if(next_state == 4'h4) begin
            ble_enc_start <= 1'b0;
            if(ble_enc_done) begin
              encoded_output <= ble_enc_output;
              next_state <= 4'h5;
            end else begin
              next_state <= next_state;
            end
          end else begin
            next_state <= next_state;
          end
        end

        4'h5: begin // Set encrypt high or low
          if(next_state == 4'h5) begin
            if(decoded_cmd == 16'h1) begin
              encryption_passthrough <= 1'b1;
            end else if (decoded_cmd == 16'h2) begin
              encryption_passthrough <= 1'b0;
            end else begin
              encryption_passthrough <= encryption_passthrough;
            end
            next_state <= 4'h0;
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