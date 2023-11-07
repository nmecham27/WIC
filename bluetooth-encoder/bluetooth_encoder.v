module bluetooth_encoder (
  input wire[32:0] input_data,
  input wire reset,
  output reg [127:0]
  output reg done
);

parameter ASCII_A = 65; // ASCII value for 'A'
parameter ASCII_B = 66; // ASCII value for 'A'
parameter ASCII_C = 67; // ASCII value for 'A'
parameter ASCII_D = 68; // ASCII value for 'A'
parameter ASCII_E = 69; // ASCII value for 'A'
parameter ASCII_F = 70; // ASCII value for 'A'
parameter ASCII_G = 71; // ASCII value for 'A'
parameter ASCII_H = 72; // ASCII value for 'A'
parameter ASCII_I = 73; // ASCII value for 'A'
parameter ASCII_J = 74; // ASCII value for 'A'
parameter ASCII_K = 75; // ASCII value for 'A'
parameter ASCII_L = 76; // ASCII value for 'A'
parameter ASCII_M = 77; // ASCII value for 'A'
parameter ASCII_N = 78; // ASCII value for 'A'
parameter ASCII_O = 79; // ASCII value for 'A'
parameter ASCII_P = 80; // ASCII value for 'A'
parameter ASCII_Q = 81; // ASCII value for 'A'
parameter ASCII_R = 82; // ASCII value for 'A'
parameter ASCII_S = 83; // ASCII value for 'A'
parameter ASCII_T = 84; // ASCII value for 'A'
parameter ASCII_U = 85; // ASCII value for 'A'
parameter ASCII_V = 86; // ASCII value for 'A'
parameter ASCII_W = 87; // ASCII value for 'A'
parameter ASCII_X = 88; // ASCII value for 'A'
parameter ASCII_Y = 89; // ASCII value for 'A'
parameter ASCII_Z = 90; // ASCII value for 'A'
parameter ASCII_+ = 43; // ASCII value for 'A'

//AT+BLEUARTTX
reg [95:0] tx_command;

always @(posedge reset) begin
  if (reset) begin
    // Set the tx_command register to "AT+BLEUARTTX"
    tx_command <= {ASCII_A, ASCII_T, ASCII_+, ASCII_B, ASCII_L, ASCII_E, ASCII_U, ASCII_A, ASCII_R, ASCII_T, ASCII_T, ASCII_X};
  end else begin
    // Set the tx_command register to "AT+BLEUARTTX"
    tx_command <= {ASCII_A, ASCII_T, ASCII_+, ASCII_B, ASCII_L, ASCII_E, ASCII_U, ASCII_A, ASCII_R, ASCII_T, ASCII_T, ASCII_X};
  end
end

always @(posedge reset or input_data) begin
  if (reset) begin
    // Reset output_data to 0
    output_data <= 0;
  end else begin
    // Concatenate tx_command and input_data and store it in output_data
    output_data <= {tx_command, input_data};
  end
end

endmodule