`ifndef _I2C_SAMPLER_
`define _I2C_SAMPLER_

`default_nettype none `timescale 1us / 100 ns

`include "i2c_periph.sv"

// We oversample the incoming clock signal so we can detect
// Start, Repeated Start, and Stop conditions and signal those to
// the I2C peripheral controller.

module i2c_sampler (
    input logic clk,  // using SCL for our clock.
    input logic sck,
    input logic reset,
    input logic read_channel,
    output logic [7:0] direction,  // set to the correct mask before using read_channel or write_channel
    output logic write_channel
);

  localparam [7:0] SampleClockDivider = 8'd32;

  // What conditions have been seen on the wire.
  logic start_condition;
  logic repeated_start_condition;
  logic stop_condition;

  i2c_periph i2c_periph (
      .system_clk(clk),
      .sck(sck),
      .reset(reset),
      .read_channel(read_channel),
      .direction(direction),
      .write_channel(write_channel),
      .start_condition(start_condition),
      .repeated_start_condition(repeated_start_condition),
      .stop_condition(stop_condition)
  );

  logic [7:0] sample_clk;
  logic [7:0] sample_clk_counter;

  always @(posedge clk) begin
    if (reset) begin
      sample_clk <= 0;
      sample_clk_counter <= 0;
      start_condition <= 0;
      repeated_start_condition <= 0;
      stop_condition <= 0;
    end else begin
      if (sample_clk_counter == SampleClockDivider) begin
        // set up clock divider with a quotient of 32
        sample_clk_counter <= 0;
        sample_clk <= 1;
      end else begin
        sample_clk_counter <= sample_clk_counter + 1;
        sample_clk <= 0;
      end
    end
  end

  logic [2:0] current_condition;
  localparam [2:0] StartCondition = 3'b001;
  localparam [2:0] StopCondition = 3'b010;

  always @(posedge sample_clk) begin
    // We are looking for the following conditions. While a clk is still high, do we see: Low to High, High to Low.
    if (current_condition == StartCondition) begin
      // If we see another START then that is a repeated_start
    end
  end

endmodule
`endif
