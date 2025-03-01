`ifndef _I2C_SAMPLER_
`define _I2C_SAMPLER_

`default_nettype none


`include "i2c_periph.sv"

// We oversample the incoming clock signal so we can detect
// Start, Repeated Start, and Stop conditions and signal those to
// the I2C peripheral controller.

module i2c_sampler (
    input logic clk,
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

  // Synchronization variables
  logic unsynced_sck;
  logic synced_sck;

  logic unsynced_sda;
  logic synced_sda;
  logic seen_start;
  logic seen_repeated_start;
  logic seen_stop;

  i2c_periph i2c_periph (
      .system_clk(clk),
      .sck(sck),
      .reset(reset),
      .read_channel(read_channel),
      .direction(direction),
      .write_channel(write_channel),
      .start_condition(start_condition),
      .repeated_start_condition(repeated_start_condition),
      .stop_condition(stop_condition),
      .seen_start(seen_start),
      .seen_repeated_start(seen_repeated_start),
      .seen_stop(seen_stop)
  );

  logic sda_high_seen;

  reg   seen_start_r;
  assign seen_start = seen_start_r;

  reg seen_repeated_start_r;
  assign seen_repeated_start = seen_repeated_start_r;

  reg seen_stop_r;
  assign seen_stop = seen_stop_r;

  always @(posedge clk) begin
    if (reset) begin
      start_condition <= 0;
      repeated_start_condition <= 0;
      stop_condition <= 0;
      unsynced_sck <= 0;
      synced_sck <= 0;
      unsynced_sda <= 0;
      synced_sda <= 0;
      sda_high_seen <= 0;
      seen_start_r <= 0;
      seen_repeated_start_r <= 0;
      seen_stop_r <= 0;
    end else begin
      // Synchronize sck and sda as they on another clock domain (sck)
      unsynced_sck <= sck;  // CDC for SCK
      synced_sck   <= unsynced_sck;

      unsynced_sda <= read_channel;  // CDC for SDA
      synced_sda   <= unsynced_sda;

      // TODO: In a single SCK pulse, when SDA goes high then low, set start_condition.
      // TODO: Once start_condition occurs, if a SDA pulse goes high then low, then restart_condition
      // TODO: Once start_condition occurs, if a SDA pulse goes low then high, then stop_condition.
      // TODO: When stable_sck goes high and sda is high, use a negative edge tracker to find START and REPEATED_START
      if (synced_sck == 1'b1) begin
        start_condition <= sda_high_seen && (synced_sda == 1'b0);
        sda_high_seen <= sda_high_seen || (synced_sda == 1'b1);
        seen_start_r <= seen_start_r || start_condition;  // if this ever goes high, it stays high.
      end else begin  // sck is low so reset all state
        sda_high_seen   <= 0;
        start_condition <= 0;
      end
    end
  end

endmodule
`endif
