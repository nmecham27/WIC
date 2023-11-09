module spi_encoder (
    input wire clk,         // Clock signal
    input wire rst_n,       // Active-low reset
    input wire roll_cmd,    // Roll command signal
    input wire [7:0] roll_data, // Data for the "roll" command
    output wire mosi,       // Master Out Slave In (SPI data out)
    output wire sclk        // SPI clock
);

reg [7:0] tx_data;
wire [7:0] tx_data_shifted;
wire start_bit, stop_bit;

// FSM states for SPI encoding
parameter IDLE = 3'b000;
parameter CMD_ACTIVE = 3'b001;
parameter DATA_ACTIVE = 3'b010;

reg [2:0] state, next_state;

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
            if (roll_cmd) begin
                tx_data <= 8'b01000001; // "roll" command
                start_bit <= 1'b1;
                stop_bit <= 1'b0;
                next_state <= CMD_ACTIVE;
            end else begin
                start_bit <= 1'b0;
                stop_bit <= 1'b0;
                next_state <= IDLE;
            end
        end
        CMD_ACTIVE: begin
            if (start_bit) begin
                start_bit <= 1'b0;
                next_state <= DATA_ACTIVE;
            end else begin
                next_state <= CMD_ACTIVE;
            end
        end
        DATA_ACTIVE: begin
            if (stop_bit) begin
                stop_bit <= 1'b0;
                next_state <= IDLE;
            end else begin
                next_state <= DATA_ACTIVE;
            end
        end
        default: next_state <= IDLE;
    endcase
end

assign tx_data_shifted = {start_bit, tx_data, stop_bit};
assign sclk = (state == CMD_ACTIVE || state == DATA_ACTIVE);
assign mosi = tx_data_shifted[7];

endmodule