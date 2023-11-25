module uart_tx( 
	input wire byte_ready,
	input wire t_byte,
	input wire load_xmt_reg,
	input wire clk,
	input wire reset,
	input wire [7:0] data_bus,
	output reg serial_out );

localparam idle = 4'h0;
localparam shift_reg = 4'h1;
localparam transmit_byte = 4'h2;
localparam clear = 4'h3;
localparam reset_state = 4'h4;
localparam start_bit = 1'b0;
localparam stop_bit = 1'b1;

reg [3:0] current_state = idle;
reg [3:0] next_state = idle;
reg [9:0] shift_register = 10'h0;
reg [7:0] data_register;
integer count = 0;

initial begin
	serial_out = 1'b1;
end

always @(current_state, byte_ready, t_byte, count) begin
	case(current_state)
	idle:
	begin
		if(byte_ready == 1'b1) begin
			next_state <= shift_reg;
		end
	end
	shift_reg:
	begin
		if(t_byte == 1'b1) begin
			next_state <= transmit_byte;
		end
	end
	transmit_byte:
	begin
		if( count >= 10 ) begin
			next_state <=  clear;
		end
	end
	clear:
	begin
		next_state <= idle;
	end
	reset_state:
	begin
		next_state <= idle;
	end
	default:
	begin
		next_state <= idle;
	end
	endcase
end

always @(posedge load_xmt_reg or posedge reset) begin
	if(reset == 1'b1) begin
		data_register <= 8'h0;
	end
	else begin
		data_register <= data_bus;
	end
end

always @(posedge clk or posedge reset) begin
	if(reset == 1'b1) begin
		current_state <= reset_state;
	end
	else begin
		current_state <= next_state;
	end
end

always @(current_state) begin
	if(current_state == shift_reg)
	begin
		shift_register[0] = start_bit;
		shift_register[8:1] = data_register;
		shift_register[9] = stop_bit;
	end
end

always @(posedge clk or posedge reset) begin
	if(reset == 1'b1) begin
		serial_out = 1'b1;
		count = 0;
	end
	else if(current_state == transmit_byte && count < 10) begin
		serial_out = shift_register[0];
		shift_register = shift_register >> 1;
		count = count + 1;
	end
	else if (current_state == clear) begin
		count = 0;
	end
end

endmodule
