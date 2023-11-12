//get some encryption and change it into a command
//get data back and send it to be encrypted.
module spi_decoder (
    input wire clk,         // Clock signal
    input wire rst_n,       // Active-low reset
    input wire miso,        // Master In Slave Out (SPI data in)
    output wire roll_cmd,   // Roll command signal
    input wire roll_data    // Data received for the "roll" command
);

 // RX (MISO) Signals
   output reg [$clog2(MAX_BYTES_PER_CS+1)-1:0] o_RX_Count,  // Index RX byte
   output       o_RX_DV,     // Data Valid pulse (1 clock cycle)
   output [7:0] o_RX_Byte,   // Byte received on MISO

reg [7:0] rx_data;
reg roll_cmd_detected;

// FSM states for SPI decoding
parameter IDLE = 2'b00;
parameter CMD_RECEIVED = 2'b01;
parameter DATA_RECEIVED = 2'b10;

reg [1:0] state, next_state;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end

always @* begin
    case (state)
        IDLE: begin
            rx_data <= 8'b0;
            roll_cmd_detected <= 1'b0;
            if (miso == 1'b0) begin
                next_state <= CMD_RECEIVED;
            end else begin
                next_state <= IDLE;
            end
        end
        CMD_RECEIVED: begin
            rx_data <= {rx_data[6:0], miso};
            if (rx_data == 8'b01000001) begin
                roll_cmd_detected <= 1'b1;
            end
            next_state <= DATA_RECEIVED;
        end
        DATA_RECEIVED: begin
            roll_cmd_detected <= 1'b0;
            next_state <= IDLE;
        end
        default: next_state <= IDLE;
    endcase
end

// Output signals
assign roll_cmd = roll_cmd_detected;

endmodule