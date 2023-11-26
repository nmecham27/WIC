module uart_rx #(
  parameter BAUD_RATE = 9600,
  parameter CLOCK_FREQ = 38400000
)(
  input wire clk,
  input wire rst,
  input wire rx,
  input wire soft_reset,
  output reg [7:0] data,
  output reg valid
);

  reg [3:0] state;
  reg [3:0] next_state;
  reg [15:0] count;
  reg [3:0] baud_count;
  reg [7:0] shift_reg;
  wire baud_clk;
  reg baud_rst;

  // Instance of baud_rate_generator module
  baud_rate_generator #(
    .BAUD_RATE(BAUD_RATE),
    .CLOCK_FREQ(CLOCK_FREQ)
  ) baud_gen (
    .clk(clk),
    .reset(baud_rst),  // Connect baud_rst to reset
    .baud_out(baud_clk)  // Connect baud_out to baud_clk
  );
  
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state <= 4'b0000;
    end else begin
      state <= next_state;
    end
  end

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      count <= 0;
    end else begin
      if (state == 4'b0001) begin
        count <= count + 1;
      end else begin
        count <= 0;
      end
    end
  end
  
  always @(rst or state or rx or baud_count or count or soft_reset) begin
    if (rst) begin
      next_state <= 4'h0;
      valid <= 1'b0;
      data <= 8'b0;
    end else if (soft_reset) begin
      valid <= 1'b0;
    end else begin  
      case (state)
        4'b0000: begin  // Idle state
          if(next_state == 4'h0) begin
            if (!rx) begin
              next_state <= 4'b0001;  // Start bit detected, move to next state
            end else begin
              next_state <= 4'b0000;
            end
          end else begin
            next_state <= next_state;
          end
        end
        4'b0001: begin  // Baud offset state
          if(next_state == 4'h1) begin
            if (count < (((CLOCK_FREQ/BAUD_RATE)/2)+15)) begin
              baud_rst <= 1'b1;
            end else begin
              valid <= 1'b0;
              baud_rst <= 1'b0;
              next_state <= 4'b0010;
            end
          end else begin
            next_state <= next_state;
          end
        end
        4'b0010: begin  // Data state
          if(next_state == 4'h2) begin
            if (baud_count == 8) begin
              next_state <= 4'b0011;  // All data bits received, move to next state
            end
          end else begin
            next_state <= next_state;
          end
        end
        4'b0011: begin  // Stop bit state
          if(next_state == 4'h3) begin
            if (baud_count >= 9 && baud_count < 10) begin
              if(rx) begin
                valid <= 1'b1;
                data[0] <= shift_reg[0];
                data[1] <= shift_reg[1];
                data[2] <= shift_reg[2];
                data[3] <= shift_reg[3];
                data[4] <= shift_reg[4];
                data[5] <= shift_reg[5];
                data[6] <= shift_reg[6];
                data[7] <= shift_reg[7];
                next_state <= 4'b0000;  // Stop bit received, return to idle state
              end
            end else if (baud_count >= 10) begin
              next_state <= 4'b0000;  // Stop bit not received, return to idle state
              valid <= 1'b0;
            end
            else begin
              next_state <= 4'b0011; // keep in this state
            end
          end else begin
            next_state <= next_state;
          end
        end
        default: next_state <= 4'b0000;
      endcase
    end
  end

  always @(posedge baud_clk or posedge baud_rst or posedge rst) begin
    if(rst) begin
      shift_reg <= 11'b00000000000;
    end else if (baud_rst) begin
      baud_count <= 4'h0;
    end else if (state == 4'b0010) begin
      shift_reg[baud_count] <= rx;
      baud_count <= baud_count + 4'h1;
    end else if (state == 4'b0011) begin
      baud_count <= baud_count + 4'h1;
    end else begin
      baud_count <= 4'h0;
    end
  end

endmodule
