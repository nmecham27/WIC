module uart_tx (
  input wire clk,
  input wire reset,
  input wire start_transmit,
  input wire [7:0] data,
  input wire load_data,
  output reg tx_data,
  output reg tx_finish
);

  reg [3:0] state;
  reg [3:0] next_state;
  reg [10:0] bit_count;
  reg [7:0] shift_register;
  reg reset_bit_count;

  
  always @(posedge clk or posedge reset) begin
    if(reset) begin
      next_state <= 4'h0;
      tx_data <= 1'b1;
      reset_bit_count <= 1'b0;
    end else begin
      case (state)
        4'b0000: begin // Idle state
          if(next_state == 4'h0) begin
            if (start_transmit) begin
              next_state <= 4'b0001; // Transition to Start bit state
              reset_bit_count <= 1'b1;
            end else begin
              tx_data <= 1'b1;
              reset_bit_count <= 1'b0;
            end
          end else begin
            next_state <= next_state;
          end
        end
        4'b0001: begin // Start bit
          if(next_state == 4'h1) begin
            reset_bit_count <= 1'b0;
            if (bit_count > 1) begin
              tx_data <= 1'b0;
              next_state <= 4'b0010;
            end else begin
              next_state <= next_state;
            end
          end else begin
            next_state <= next_state;
          end
        end
        4'b0010: begin // Data bits
          if(next_state == 4'h2) begin
            if (bit_count >= 10) begin
              tx_data <= shift_register[bit_count-3];
              next_state <= 4'b0100; // Transition to Stop bit state
            end else if (bit_count >= 3 && bit_count < 10) begin
              tx_data <= shift_register[bit_count-3];
            end else begin
              next_state <= 4'b0001;
            end
          end else begin
            next_state <= next_state;
          end
        end
        4'b0100: begin // Stop bit
          if(next_state == 4'h4) begin
            next_state <= 4'b0000; // Transition back to Idle state
            tx_data <= 1'b1; // Stop bit is always 1
          end else begin
            next_state <= next_state;
          end
        end

        default: begin
          next_state <= 4'h0;
        end

      endcase
    end
  end

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      bit_count <= 11'b0;
    end else if (reset_bit_count) begin
      bit_count <= 11'b0;
    end else begin
      case (state)
        4'b0000: begin // Idle state
          bit_count <= 11'b0;
        end
        4'b0001: begin // Start bit stat count
          bit_count <= bit_count + 11'b1;
        end
        4'b0010: begin // Data bits
          bit_count <= bit_count + 11'b1;
        end
        default: begin
          bit_count <= bit_count;
        end
      endcase
    end
  end

  always @(posedge clk or posedge reset or posedge start_transmit) begin
    if (reset) begin
      tx_finish <= 1'b1;
    end else if (start_transmit) begin
      tx_finish <= 1'b0;
    end else begin
      case (next_state)
        4'b0000: begin // Idle state
          tx_finish <= 1'b1;
        end
        default: begin
          tx_finish <= tx_finish;
        end
      endcase
    end
  end

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      state <= 4'b0000;
    end else begin
      state <= next_state;
    end
  end

  always @(posedge load_data) begin
    if (load_data) begin
      shift_register <= data;
    end else begin
      shift_register <= shift_register; // Just keep the same value
    end
  end

endmodule
