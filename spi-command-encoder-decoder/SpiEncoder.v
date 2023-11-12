module spi_encoder (
    input wire clk,         // Clock signal
    input wire rst_n,       // Active-low reset
    input wire transmit,    // Command was recieved
    input wire transmitRecieved, //the transmission was recieved by the spi and it is ready for the next byte
    input wire [2:0] command,    // Roll command signal
    output reg mosi,       // Master Out Slave In (SPI data out) Signal is ready to send
    output reg [7:0] addressToTransfer, //the command register to read
    output reg [1:0] i_TX_Count, // each instruction we send needs to recieve back two bytes
    output reg transmissionSent //our byte was sent and we are ready for another
);
   
//input commands for information to recieve
parameter GETROLLANGULAR = 3'b000; 
parameter GETROLLLINEAR = 3'b001;
parameter GETPITCHANGULAR = 3'b010;
parameter GETPITCHLINEAR = 3'b011;
parameter GETYAWANGULAR = 3'b100;
parameter GETYAWLINEAR =  3'b101;

reg start_bit;

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
            
            if (transmit) begin
                case (command)
                    GETROLLANGULAR: begin //address 24h low, 25h high
                        addressToTransfer <= 8'b10100100;
                    end
                    GETROLLLINEAR: begin //address 2Ah low, 2Bh high
                        addressToTransfer <= 8'b10101010;
                    end
                    GETPITCHANGULAR: begin  //address 22h low, 23h high 
                        addressToTransfer <= 8'b10100010;
                    end
                    GETPITCHLINEAR: begin //address 28h low, 29h high
                        addressToTransfer <= 8'b10101000;
                    end
                    GETYAWANGULAR: begin //address 26h low, 27h high
                        addressToTransfer <= 8'b10100110;
                    end
                    GETYAWLINEAR: begin //address 2Ch low, 2Dh high
                        addressToTransfer <= 8'b10101100;
                    end
                    default: ;
                endcase
                start_bit <= 1'b1;
                transmissionSent <= 1'b0;
                next_state <= CMD_ACTIVE;
            end else begin
                start_bit <= 1'b0;
                next_state <= IDLE;
                transmissionSent <= 1'b1;
            end
        end
        CMD_ACTIVE: begin
            if (start_bit) begin
                i_TX_Count <= 2'b10;
                mosi <= 1'b1;
                next_state <= DATA_ACTIVE;
            end else begin
                next_state <= CMD_ACTIVE;
            end
        end
        DATA_ACTIVE: begin
            if (transmitRecieved) begin
                transmissionSent <= 1'b1;
                mosi <= 1'b0;
                next_state <= IDLE;
            end else begin
                start_bit <= 1'b0;
                next_state <= DATA_ACTIVE;
            end
        end
        default: next_state <= IDLE;
    endcase
end


endmodule