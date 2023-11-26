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
  reg [3:0] go_back_state;
  reg [1023:0] internal_value_holder;
  reg timeout_alarm;
  reg reset_timeout_alarm;
  reg accumulate_low_flag;
  reg clear_accumulate_low_flag;
  integer output_index;
  integer timeout_count;

  wire state_0;
  wire state_1;
  wire state_2;
  wire state_3;
  wire accumulate_low_flag_w;
  wire timeout_alarm_w;

  assign state_0 = state[0];
  assign state_1 = state[1];
  assign state_2 = state[2];
  assign state_3 = state[3];
  assign accumulate_low_flag_w = accumulate_low_flag;
  assign timeout_alarm_w = timeout_alarm;

  always @( posedge clk or posedge reset) begin
    if(reset) begin
      output_data <= 1024'h0;
      output_data_size <= 8'h0;
      done <= 1'b1;
      next_state <= 4'h0;
      output_index <= 7;
      error <= 1'b0;
      reset_timeout_alarm <= 1'b1;
      internal_value_holder <= 1024'h0;
      go_back_state <= 4'h0;
      clear_accumulate_low_flag <= 0;
    end else if(soft_reset) begin
      done <= 1'b0;
    end else begin
      clear_accumulate_low_flag <= 0; // For ease of using just clear this flag before doing anything
      case(state)
        4'h0: begin // Initial state
          if(accumulate && next_state == 4'h0) begin
            next_state <= 4'h4; // Move to accumulate state
            go_back_state <= 4'h1;
            done <= 1'b0;
            error <= 1'b0;
            output_data <= 1024'h0;
            reset_timeout_alarm <= 1'b0;
            output_data_size <= 8'h1;
            internal_value_holder[output_index -: 8] <= input_data;
            output_index <= output_index + 8;
          end else if(next_state == 4'h0) begin
            next_state <= 4'h0; // Stay in this state
            done <= 1'b1;
            reset_timeout_alarm <= 1'b1;
            output_index <= 7;
            internal_value_holder <= 1024'h0;
          end else begin
            next_state <= next_state;
          end
        end

        4'h1: begin // Accumulate state
          if(next_state == 4'h1) begin
            if(accumulate && !timeout_alarm) begin
              if(ble_side) begin
                if(input_data != 8'h0D) begin // check for carriage return
                  if(output_index <= 1023) begin
                    internal_value_holder[output_index -: 8] <= input_data[7:0];
                    output_index <= output_index + 8;
                    output_data_size <= output_data_size + 8'h1;
                    go_back_state <= 4'h1; // Stay in this state
                    next_state <= 4'h4;
                  end else begin
                    // We received too many bytes without getting the terminate byte,
                    // we should set the error flag and return to the initial state
                    output_index <= 7;
                    error <= 1'b1;
                    internal_value_holder <= 1024'h0;
                    next_state <= 4'h0; // Go back to initial state
                  end
                end else begin
                  next_state <= 4'h3; // Move right to the output state
                end
              end else begin
                if( input_data != 8'hBE ) begin
                  if(output_index <= 1023) begin
                    internal_value_holder[output_index -: 8] <= input_data[7:0];
                    output_index <= output_index + 8;
                    output_data_size <= output_data_size + 8'h1;
                    go_back_state <= 4'h1; // Stay in this state
                    next_state <= 4'h4;
                  end else begin
                    // We received too many bytes without getting the terminate byte,
                    // we should set the error flag and return to the initial state
                    output_index <= 7;
                    error <= 1'b1;
                    internal_value_holder <= 1024'h0;
                    next_state <= 4'h0; // Go back to initial state
                  end
                end else begin
                  go_back_state <= 4'h2; // Move to the final byte state
                  next_state <= 4'h4;
                end
              end
            end else if (timeout_alarm) begin
              error <= 1'b1;
              output_index <= 7;
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
                output_index <= 7;
                internal_value_holder <= 1024'h0;
                next_state <= 4'h0; // Go back to initial state
              end else begin
                next_state <= 4'h3; // Move to the final output state
              end
            end else if (timeout_alarm) begin
              error <= 1'b1;
              output_index <= 7;
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
            output_data <= internal_value_holder;
            done <= 1'b1;
            next_state <= 4'h5;
            go_back_state <= 4'h0;
          end else begin
            next_state <= next_state;
          end
        end

        4'h4: begin // Wait for accumulate to go low
          if(next_state <= 4'h4) begin
            if(accumulate_low_flag && !timeout_alarm) begin
              next_state <= go_back_state;
              clear_accumulate_low_flag <= 1;
            end else if (timeout_alarm) begin
              error <= 1'b1;
              output_index <= 7;
              internal_value_holder <= 1024'h0;
              next_state <= 4'h0; // Go back to initial state
            end else begin
              next_state <= next_state;
            end
          end
        end

        4'h5: begin // Special wait for accumulate to go low that won't cause alarm
          if(next_state <= 4'h5) begin
            if(accumulate_low_flag) begin
              next_state <= go_back_state;
              clear_accumulate_low_flag <= 1;
            end else begin
              next_state <= next_state;
            end
          end
        end
        default: begin
          next_state <= 4'h0;
        end
      endcase
    end
  end

  always @(posedge reset or negedge accumulate or posedge clear_accumulate_low_flag) begin
    if(reset) begin
      accumulate_low_flag <= 0;
    end else if ( clear_accumulate_low_flag ) begin
      accumulate_low_flag <= 0;
    end else if(state == 4'h4 || state == 4'h5) begin
      if(!accumulate) begin
        accumulate_low_flag <= 1;
      end else begin
        accumulate_low_flag <= accumulate_low_flag;
      end
    end else begin
      accumulate_low_flag <= accumulate_low_flag;
    end
  end

  always @(posedge clk or posedge reset or posedge reset_timeout_alarm) begin
    if(reset || reset_timeout_alarm) begin
      timeout_count <= 0;
      timeout_alarm <= 1'b0;
    end else begin
      if(state == 4'h1 || state == 4'h2 || state == 4'h4) begin
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
