module uart_command_accumulator #(
  parameter TIMEOUT = 2000
)(
  input wire clk,
  input wire reset,
  input wire[7:0] input_data,
  input wire accumulate,
  input wire ble_side,
  input wire soft_reset,
  output reg[1023:0] output_data,
  output reg[7:0] output_data_size,
  output reg done,
  output reg error
);

  reg [3:0] state;
  reg [3:0] next_state;
  reg [1023:0] internal_value_holder;
  reg timeout_alarm;
  reg reset_timeout_alarm;
  integer output_index;
  integer timeout_count;

  always @(posedge reset or posedge timeout_alarm or state or posedge accumulate or posedge soft_reset) begin
    if(reset) begin
      output_data <= 1024'h0;
      output_data_size <= 8'h0;
      done <= 1'b1;
      next_state <= 4'h0;
      output_index <= 7;
      error <= 1'b0;
      reset_timeout_alarm <= 1'b1;
      internal_value_holder <= 1024'h0;
    end else if(soft_reset) begin
      done <= 1'b0;
    end else begin
      case(state)
        4'h0: begin // Initial state
          if(accumulate && next_state == 4'h0) begin
            next_state <= 4'h1; // Move to accumulate state
            done <= 1'b0;
            error <= 1'b0;
            output_data <= 1024'h0;
            reset_timeout_alarm <= 1'b0;
            output_data_size <= 8'h1;
            internal_value_holder[output_index -: 8] = input_data;
            output_index = output_index + 8;
          end else if(next_state == 4'h0) begin
            next_state <= 4'h0; // Stay in this state
            done <= 1'b1;
            reset_timeout_alarm <= 1'b1;
            output_index = 7;
            internal_value_holder <= 1024'h0;
          end else begin
            next_state <= next_state;
          end
        end

        4'h1: begin // Accumualte state
          if(next_state == 4'h1) begin
            if(accumulate && !timeout_alarm) begin
              if(ble_side) begin
                if(input_data != 8'h0D) begin // check for carriage return
                  if(output_index <= 1023) begin
                    internal_value_holder[output_index -: 8] = input_data[7:0];
                    output_index = output_index + 8;
                    output_data_size = output_data_size + 8'h1;
                    next_state = 4'h1; // Stay in this state
                  end else begin
                    // We received too many bytes without getting the terminate byte,
                    // we should set the error flag and return to the initial state
                    output_index = 7;
                    error <= 1'b1;
                    internal_value_holder <= 1024'h0;
                    next_state <= 4'h0; // Go back to initial state
                  end
                end else begin
                  next_state = 4'h3; // Move right to the output state
                end
              end else begin
                if( input_data != 8'hBE ) begin
                  if(output_index <= 1023) begin
                    internal_value_holder[output_index -: 8] = input_data[7:0];
                    output_index = output_index + 8;
                    output_data_size = output_data_size + 8'h1;
                    next_state = 4'h1; // Stay in this state
                  end else begin
                    // We received too many bytes without getting the terminate byte,
                    // we should set the error flag and return to the initial state
                    output_index = 7;
                    error <= 1'b1;
                    internal_value_holder <= 1024'h0;
                    next_state <= 4'h0; // Go back to initial state
                  end
                end else begin
                  next_state = 4'h2; // Move to the final byte state
                end
              end
            end else if (timeout_alarm) begin
              error <= 1'b1;
              output_index = 7;
              internal_value_holder <= 1024'h0;
              next_state <= 4'h0; // Go back to initial state
            end else begin
              next_state <= next_state; // Stay in this state
            end
          end else begin
            next_state <= next_state;
          end
        end

        4'h2: begin // Final byte check state
          if(next_state == 4'h2) begin
            if(accumulate && !timeout_alarm) begin
              if( input_data != 8'hEF ) begin
                error <= 1'b1;
                output_index = 7;
                internal_value_holder <= 1024'h0;
                next_state <= 4'h0; // Go back to initial state
              end else begin
                next_state = 4'h3; // Move to the final output state
              end
            end else if (timeout_alarm) begin
              error <= 1'b1;
              output_index = 7;
              internal_value_holder <= 1024'h0;
              next_state <= 4'h0; // Go back to initial state
            end else begin
              next_state <= next_state; // Stay in this state
            end
          end else begin
            next_state <= next_state;
          end
        end

        4'h3: begin // Output state
          if(next_state == 4'h3) begin
            output_data = internal_value_holder;
            done <= 1'b1;
            next_state <= 4'h0;
          end else begin
            next_state <= next_state;
          end
        end

      endcase
    end
  end

  always @(posedge clk or posedge reset or posedge reset_timeout_alarm) begin
    if(reset || reset_timeout_alarm) begin
      timeout_count <= 0;
      timeout_alarm <= 1'b0;
    end else begin
      if(state == 4'h1) begin
        if(timeout_count > TIMEOUT) begin
          timeout_alarm <= 1'b1;
        end else begin
          timeout_count <= timeout_count + 1;
        end
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