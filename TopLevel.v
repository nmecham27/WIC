module TopLevel#( 
    parameter BAUD_RATE = 9600,
    parameter CLOCK_FREQ = 38400000
    parameter SPI_MODE = 0,
    parameter CLKS_PER_HALF_BIT = 2,
    parameter TIMEOUT = 2000
)
(
    input clk,
    input reset,
    input mode,
    input [1:0] upDown,     
    input [1:0] forwardBack,
    input [1:0] rightLeft
    output [143:0] output_data
    // output i dont know what to put here


)
    reg [7:0] uart_tx, uart_rx;
    wire uart_valid;
    wire tx_done;
    wire uart_load_data;
    wire start_uart;
    wire [1023:0] accum_data;
    wire [7:0] accum_data_size;
    wire enc_dec_start, enc_dec_passthrough, encr_decr_done;
    wire spi_start, spi_valid_tx, spi_valid_rx;
    wire bluetooth_done;


top_level_uart #(
    .BAUD_RATE(BAUD_RATE),
    .CLOCK_FREQ(CLOCK_FREQ)
    ) uart1 (
    .clk(clk), 
    .reset(reset), 
    .uart_tx(uart_tx), 
    .start_transmit(start_uart), 
    .load_data(uart_load_data), 
    .uart_rx(uart_rx), 
    .valid(uart_valid), 
    .tx_done(tx_done)
);  
uart_command_accumulator #(
    .TIMEOUT(TIMEOUT)
    ) uartcomac(
    .clk(clk),
    .reset(reset),
    .input_data(uart_rx),
    .accumulate(),
    .ble_side(),
    .output_data(accum_data),
    .output_data_size(accum_data_size),
    .done(),
    .error()

);

host_uart_command_dec uartcomdec(
   .clk(clk),
   .reset(reset),
   .input_data(accum_data),
   .start(),
   .output_data(), // The command that comes out will be 255 bytes
   .done(),
   .error(),
  //output reg encrypt_enable,
   .cmd_select()
);
// command encoder & decoder module

SPI_Master #(
    .SPI_MODE(SPI_MODE),
    .CLKS_PER_HALF_BIT(CLKS_PER_HALF_BIT)
)   spi(
     .i_Rst_L(reset),     
     .i_Clk(clk),       
     .i_TX_Byte(   ),        
     .i_TX_DV(spi_valid_tx),          
     .o_TX_Ready(spi_start),       
     .o_RX_DV(spi_valid_rx),     
     .o_RX_Byte(   ),  
     .o_SPI_Clk(clk),
     .i_SPI_MISO(  ),
     .o_SPI_MOSI(  )
)
otp_encryption_decryption otp(
    .input_data(command_output),
    .reset(reset),
    .passthrough(enc_dec_passthrough),
    .start(enc_dec_start),
    .output_data(uart_rx),
    .done(encr_decr_done)
)

bluetooth_encoder be(

    .input_data( ),
    .command_select(cmd_select),
    .start(encr_decr_done),
    .clk(clk),
    .reset(reset),
    .output_data( output_data  ),
    .done(bluetooth_done)
)

// top_level_uart #(
//     .BAUD_RATE(BAUD_RATE),
//     .CLOCK_FREQ(CLOCK_FREQ)
//     ) uart2 (
//     .clk(clk), 
//     .reset(reset), 
//     .uart_tx(uart_tx), 
//     .start_transmit(start_uart), 
//     .load_data(uart_load_data), 
//     .uart_rx(uart_rx), 
//     .valid(uart_valid), 
//     .tx_done(tx_done)
// );  



endmodule