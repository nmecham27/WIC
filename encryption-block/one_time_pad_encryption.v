module otp_encryption_decryption (
  input wire[15:0] input_data,
  input wire reset,
  input wire passthrough,
  input wire start,
  output reg[15:0] output_data,
  output reg done
);

  reg [15:0] key;
  reg [3:0] state;
  reg [3:0] next_state;
  reg locked_for_single_transaction;

  always @(posedge reset, posedge input_data, posedge state, posedge start) begin
    if (reset) begin
      key <= 16'h3327;
      output_data <= 16'h00;
      next_state <= 4'b0000;
      done <= 1'b1;
    end else if (!passthrough) begin
      case(state)
        4'b0000: begin // Idle state
          if (start && !locked_for_single_transaction) begin
            done <= 1'b0;
            next_state <= 4'b0001; // Move to encrypt/decrypt state
          end else begin
            next_state <= 4'b0000; // Keep in idle
          end
        end
        4'b0001: begin // Encrypt/Decrypt state
          output_data <= input_data ^ key;
          done <= 1'b1;
          next_state <= 4'b0000;
        end
        default: begin
          next_state <= 4'b0000;
        end
      endcase
    end else begin
      output_data <= input_data;
    end
  end

  always @(next_state) begin
    state <= next_state;
  end

  always @(negedge start, posedge reset, posedge state) begin
    if (!start || reset) begin
      locked_for_single_transaction <= 1'b0;
    end else begin
      if (state == 4'b0001) begin
        locked_for_single_transaction <= 1'b1;
      end else begin
        locked_for_single_transaction <= locked_for_single_transaction;
      end
    end    

  end
endmodule
