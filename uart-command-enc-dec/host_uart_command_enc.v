module host_uart_command_enc (
  input wire clk,
  input wire reset,
  input wire[263:0] input_data, // User provided data, only used in some responses
  input wire start,
  input reg[15:0] cmd_select, // Type of response to construct
  input reg suc_or_fail_status, // True for success, false or low for failure status
  output reg[1024:0] output_data, // The command that comes out will be 1024 Max bytes
  output reg done,
  output reg error
);

  parameter ENCRYPT_ENABLE_RSP_ID = 8'h02;
  parameter READ_YAW_CMD_RSP_ID = 8'h04;

  reg [3:0] state;
  reg [3:0] next_state;
  reg [263:0] internal_value_holder;
  reg internal_msg_status_holder;
  reg [15:0] internal_cmd_select;

  always @(posedge reset or posedge start or state) begin
    if(reset) begin
      done <= 1'b1;
      error <= 1'b0;
      output_data <= 1024'h0;
      internal_value_holder <= 264'h0;
      internal_cmd_select <= 16'h0;
      internal_msg_status_holder <= 1'b0; 
      next_state <= 4'h0;
    end else begin
      case(state)

        4'h0: begin // Initial state
          if(next_state == 4'h0) begin
            if(start) begin
              done <= 1'b0;
              error <= 1'b0;
              output_data <= 1024'h0;
              internal_value_holder <= input_data;
              if (suc_or_fail_status) begin
                internal_msg_status_holder = 8'h0;
              end else begin
                internal_msg_status_holder = 8'h1;
              end
              internal_cmd_select = cmd_select;
              next_state <= 4'h1;
            end else begin
              done <= 1'b1;
              internal_value_holder <= 264'h0;
              next_state <= 4'h0;
            end
          end else begin
            next_state <= next_state;
          end
        end

        4'h1: begin // Decode state
          if(next_state == 4'h1) begin
            case(internal_cmd_select)

              16'h1: begin // Enable/disable encryption command rsp
                output_data[7:0] = ENCRYPT_ENABLE_RSP_ID;
                output_data[55:7] = 48'h0;
                output_data[63:56] = internal_msg_status_holder;
                next_state <= 4'h0;
              end

              16'h2: begin // Read yaw command rsp
                output_data[7:0] = READ_YAW_CMD_RSP_ID;
                output_data[55:7] = 48'h0;
                output_data[87:56] = internal_value_holder[32:0];
                output_data[95:88] = internal_msg_status_holder;
                next_state <= 4'h0;
              end

              default: begin // Unknown command received
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