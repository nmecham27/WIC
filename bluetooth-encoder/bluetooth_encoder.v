module bluetooth_encoder (
  input wire[32:0] input_data,
  input wire [3:0] command_select,
  input wire start,
  input wire clk,
  input wire reset,
  output reg [127:0] output_data,
  output reg done
);

parameter ASCII_A = 65; // ASCII value for 'A'
parameter ASCII_B = 66; // ASCII value for 'B'
parameter ASCII_C = 67; // ASCII value for 'C'
parameter ASCII_D = 68; // ASCII value for 'D'
parameter ASCII_E = 69; // ASCII value for 'E'
parameter ASCII_F = 70; // ASCII value for 'F'
parameter ASCII_G = 71; // ASCII value for 'G'
parameter ASCII_H = 72; // ASCII value for 'H'
parameter ASCII_I = 73; // ASCII value for 'I'
parameter ASCII_J = 74; // ASCII value for 'J'
parameter ASCII_K = 75; // ASCII value for 'K'
parameter ASCII_L = 76; // ASCII value for 'L'
parameter ASCII_M = 77; // ASCII value for 'M'
parameter ASCII_N = 78; // ASCII value for 'N'
parameter ASCII_O = 79; // ASCII value for 'O'
parameter ASCII_P = 80; // ASCII value for 'P'
parameter ASCII_Q = 81; // ASCII value for 'Q'
parameter ASCII_R = 82; // ASCII value for 'R'
parameter ASCII_S = 83; // ASCII value for 'S'
parameter ASCII_T = 84; // ASCII value for 'T'
parameter ASCII_U = 85; // ASCII value for 'U'
parameter ASCII_V = 86; // ASCII value for 'V'
parameter ASCII_W = 87; // ASCII value for 'W'
parameter ASCII_X = 88; // ASCII value for 'X'
parameter ASCII_Y = 89; // ASCII value for 'Y'
parameter ASCII_Z = 90; // ASCII value for 'Z'
parameter ASCII_PLUS = 43; // ASCII value for '+'

//AT+BLEUARTTX
reg [95:0] tx_command;
//AT+BLEUARTRX
reg [95:0] rx_command;

reg [3:0] state;
reg [3:0] next_state;

integer i;

always @(posedge clk or posedge reset) begin
  if(reset) begin
    state <= 4'h0;
  end else begin
    state <= next_state;
  end
end

always @(posedge reset or input_data or state or posedge start) begin
  if (reset) begin
    // Reset output_data to 0
    output_data <= 0;

    // Set the tx_command register to "AT+BLEUARTTX"
    tx_command[7:0] <= ASCII_A;
    tx_command[15:8] <= ASCII_T;
    tx_command[23:16] <= ASCII_PLUS;
    tx_command[31:24] <= ASCII_B;
    tx_command[39:32] <= ASCII_L;
    tx_command[47:40] <= ASCII_E;
    tx_command[55:48] <= ASCII_U;
    tx_command[63:56] <= ASCII_A;
    tx_command[71:64] <= ASCII_R;
    tx_command[79:72] <= ASCII_T;
    tx_command[87:80] <= ASCII_T;
    tx_command[95:88] <= ASCII_X;

    // Set the rx_command register to "AT+BLEUARTRX"
    rx_command[7:0] <= ASCII_A;
    rx_command[15:8] <= ASCII_T;
    rx_command[23:16] <= ASCII_PLUS;
    rx_command[31:24] <= ASCII_B;
    rx_command[39:32] <= ASCII_L;
    rx_command[47:40] <= ASCII_E;
    rx_command[55:48] <= ASCII_U;
    rx_command[63:56] <= ASCII_A;
    rx_command[71:64] <= ASCII_R;
    rx_command[79:72] <= ASCII_T;
    rx_command[87:80] <= ASCII_T;
    rx_command[95:88] <= ASCII_X;

    next_state <= 4'h0;
    done = 1'b1;
  end else begin
    // Check the command_select for what command we need to encode
    case (state)
      4'h0: begin
        if (start) begin
          next_state = 4'h1;
          done = 1'b0;
        end
      end
      4'h1: begin
        case( command_select )
          4'h1: begin
            // Concatenate tx_command and input_data and store it in output_data
            output_data[95:0] = tx_command[95:0];
            output_data[103:96] = input_data[7:0];
            output_data[111:104] = input_data[15:8];
            output_data[119:112] = input_data[23:16];
            output_data[127:120] = input_data[31:24];
          end
          4'h2: begin
            // Concatenate rx_command and input_data and store it in output_data
            output_data[95:0] = rx_command[95:0];
            output_data[103:96] = input_data[7:0];
            output_data[111:104] = input_data[15:8];
            output_data[119:112] = input_data[23:16];
            output_data[127:120] = input_data[31:24];
          end
          default: begin
            output_data = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          end
        endcase
        done = 1'b1;
        next_state = 4'h0;
      end
      default: begin
      end
    endcase
  end
end

endmodule