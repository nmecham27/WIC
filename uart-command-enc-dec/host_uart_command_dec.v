module host_uart_command_dec (
  input wire clk,
  input wire reset,
  input wire[1023:0] input_data,
  input wire start,
  output reg[255:0] output_data, // The command that comes out will be 255 bytes
  output reg done,
  output reg error,
  output reg[15:0] cmd_select
);

  reg [3:0] state;
  reg [3:0] next_state;
  reg [1023:0] internal_value_holder;

  always @(posedge reset or posedge start or state) begin
    if(reset) begin
      done <= 1'b1;
      error <= 1'b0;
      //encrypt_enable <= 1'b0;
      output_data <= 256'h0;
      cmd_select <= 16'h0;
      internal_value_holder <= 1024'h0;
      next_state <= 4'h0;
    end else begin
      case(state)

        4'h0: begin // Initial state
          if(next_state == 4'h0) begin
            if(start) begin
              done <= 1'b0;
              error <= 1'b0;
              output_data <= 256'h0;
              internal_value_holder <= input_data;
              cmd_select <= 16'h0;
              next_state <= 4'h1;
            end else begin
              done <= 1'b1;
              internal_value_holder <= 1024'h0;
              next_state <= next_state;
            end
          end else begin
            next_state <= next_state;
          end
        end

        4'h1: begin // Decode state
          if(next_state == 4'h1) begin
            case(internal_value_holder[7:0])

              8'h1: begin // Enable/disable encryption command
                if(internal_value_holder[55:8] == 48'hFFFFFFFFFFFF) begin
                  if(internal_value_holder[63:56] == 8'h1) begin
                    if(internal_value_holder[71:64] == 8'h0) begin
                      cmd_select <= 16'h1;
                      //encrypt_enable <= 1'b0;
                      next_state <= 4'h0; // Go back to initial state
                    end else begin
                      cmd_select <= 16'h2;
                      //encrypt_enable <= 1'b1;
                      next_state <= 4'h0; // Go back to initial state
                    end
                  end else begin
                    cmd_select <= 16'hFFFF;
                    error <= 1'b1; // Set the error high since format was wrong
                    next_state <= 4'h0; // Go back to initial state
                  end
                end else begin
                  cmd_select <= 16'hFFFF;
                  error <= 1'b1; // Set the error high since format was wrong
                  next_state <= 4'h0; // Go back to initial state
                end
              end

              8'h3: begin // Read yaw command
                cmd_select <= 16'h3;
                output_data <= internal_value_holder[55:8]; // Save the target device
                next_state <= 4'h0; // Go back to initial state
              end

              default: begin // Unknown command received
                cmd_select <= 16'hFFFF;
                error <= 1'b1;
                next_state <= 4'h0;
              end

            endcase
          end else begin
            next_state <= next_state;
          end
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

endmodule