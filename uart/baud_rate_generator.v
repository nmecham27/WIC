module baud_rate_generator #(
  parameter BAUD_RATE = 9600,
  parameter CLOCK_FREQ = 192000
) (
  input wire clk,
  input wire reset,
  output reg baud_out
);

  reg [15:0] count;
  reg baud_tick;

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      count <= 0;
      baud_tick <= 0;
    end else begin
      count <= count + 1;
      if (count >= (CLOCK_FREQ / BAUD_RATE) / 2) begin
        baud_tick <= ~baud_tick;
        count <= 0;
      end else begin
        baud_tick <= baud_tick;
      end
    end
  end

  always @(posedge clk) begin
    baud_out <= baud_tick;
  end

endmodule