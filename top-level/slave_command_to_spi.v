`include "../spi-command-encoder-decoder/SPIDecoder.v"
`include "../spi-command-encoder-decoder/SPIEncoder.v"
`include "../spi-master/source/Spi_Master_With_Single_CS.v"
`include "../spi-master/source/Spi_Master.v"

module slave_command_to_spi(
//inputs to encoder
input wire clk,
input wire rst,
input wire transmit,
input wire [2:0] command,

//output from encoder
output wire ready,

//outputs from the decoder
output wire [7:0] tx_byte,
output wire valid_out,

//Spi Interface
output o_SPI_Clk,
input  i_SPI_MISO,
output o_SPI_MOSI,
output o_SPI_CS_n,
output [1:0]recieved_byte_count
);

//local parameters
localparam MAX_BYTES_PER_CS = 2;
localparam SPI_MODE = 0;
localparam CLKS_PER_HALF_BIT = 2;
localparam CS_INACTIVE_CLKS = 1;

//transmitted from spi to decoder
wire [7:0] received;
wire [$clog2(MAX_BYTES_PER_CS+1)-1:0] Count;
wire valid_data;

//from encoder to spi
wire [7:0] address;
wire [1:0] TX_Count;
wire Ready_From_Encoder;
wire Spi_Ready_For_Another;

assign recieved_byte_count = Count;

//instantiate the spi encoder
spi_encoder encoder(
    //inputs
    .clk(clk),         // Clock signal
    .rst_n(~rst),       // Active-low reset
    .transmit(transmit),    // Command was recieved
    .transmitRecieved(Spi_Ready_For_Another), //the transmission was recieved by the spi and it is ready for the next byte
    .spi_count(Count), 
    .command(command),    // Roll command signal
    //outputs
    .mosi(Ready_From_Encoder),       // Master Out Slave In (SPI data out) Signal is ready to send
    .addressToTransfer(address), //the command register to read
    .i_TX_Count(TX_Count), // each instruction we send needs to recieve back two bytes
    .transmissionSent(ready) //our byte was sent and we are ready for another
);

SPI_Master_With_Single_CS #( SPI_MODE,
    CLKS_PER_HALF_BIT,
    MAX_BYTES_PER_CS,
    CS_INACTIVE_CLKS
    )
    SPI
  (
   // Control/Data Signals,
   .i_Rst_L(~rst),     // FPGA Reset
   .i_Clk(clk),       // FPGA Clock
   
   // TX (MOSI) Signals
   .i_TX_Count(TX_Count),  // # bytes per CS low
   .i_TX_Byte(address),       // Byte to transmit on MOSI
   .i_TX_DV(Ready_From_Encoder),         // Data Valid Pulse with i_TX_Byte
   .o_TX_Ready(Spi_Ready_For_Another),      // Transmit Ready for next byte
   
   // RX (MISO) Signals
   .o_RX_Count(Count),  // Index RX byte
   .o_RX_DV(valid_data),     // Data Valid pulse (1 clock cycle)
   .o_RX_Byte(received),   // Byte received on MISO

   // SPI Interface
   .o_SPI_Clk(o_SPI_Clk),
   .i_SPI_MISO(i_SPI_MISO),
   .o_SPI_MOSI(o_SPI_MOSI),
   .o_SPI_CS_n(o_SPI_CS_n)
   );

spi_decoder #(
    MAX_BYTES_PER_CS
) spi_decoder(
    //inputs
    .clk(clk),         // Clock signal
    .rst_n(~rst),       // Active-low reset
    .data_valid(valid_data),        // Data valid pulse
    .RX_Count(Count),    // Number of bytes this will recieve from the spi
    .rx_byte(received),    //byte recieved from spi
    //outputs
    .tx_byte(tx_byte),   //byte to send back to the master
    .valid_out(valid_out)     //the byte is ready to transmit
);

endmodule