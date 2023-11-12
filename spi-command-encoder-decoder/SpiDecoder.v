//get some encryption and change it into a command
//get data back and send it to be encrypted.
module spi_decoder #(
    parameter MAX_BYTES_PER_CS = 2
) (
    input wire clk,         // Clock signal
    input wire rst_n,       // Active-low reset
    input wire data_valid,        // Data valid pulse
    input reg [$clog2(MAX_BYTES_PER_CS+1)-1:0] RX_Count,    // Number of bytes this will recieve from the spi
    input [7:0] rx_byte,    //byte recieved from spi
    output reg [7:0] tx_byte,   //byte to send back to the master
    output reg valid_out     //the byte is ready to transmit
);

reg [$clog2(MAX_BYTES_PER_CS+1)-1:0] bytes_counted = 0;

// FSM states for SPI decoding
parameter IDLE = 2'b00;
parameter DATA_RECEIVED = 2'b01;

reg [1:0] state, next_state;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end

always @(*) begin
    case (state)
        IDLE: begin
            if (data_valid == 1'b1) begin
                tx_byte <= rx_byte;
                valid_out <= 1'b1;
                next_state <= DATA_RECEIVED;
            end else begin
                tx_byte <= 8'b0;
                bytes_counted <= 0;
                valid_out <= 1'b0;
                next_state <= IDLE;
            end
        end
        DATA_RECEIVED: begin
            if(RX_Count == bytes_counted)begin //we recieved every byte from this transmission
                bytes_counted <= 0;
                valid_out <= 1'b0;
                next_state <= IDLE;
            end else if(data_valid == 1) begin
                tx_byte <= rx_byte;
                valid_out <= 1'b1;
                if(RX_Count-1 == bytes_counted)begin
                    next_state <= IDLE;
                end else begin
                end
            end else begin
                valid_out <= 1'b0;
            end
        end
       
        default: next_state <= IDLE;
    endcase
end

always @(*) begin
    if(data_valid)begin
        bytes_counted = bytes_counted + 1;
    end

end

endmodule