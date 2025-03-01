`ifndef _I2C_PERIPH_
`define _I2C_PERIPH_

`default_nettype none


`include "byte_transmitter.sv"
`include "byte_receiver.sv"
`include "mux_2_1.sv"
`include "async_fifo.v"

module i2c_periph (
    input sck,  // using SCL for our clock.
    input system_clk,  // the clock used by the main design
    input reset,
    input read_channel,
    output logic [7:0] direction,  // set to the correct mask before using write_channel
    output reg write_channel,
    input logic start_condition,
    input logic repeated_start_condition,
    input logic stop_condition,
    inout logic seen_start,
    inout logic seen_repeated_start,
    inout logic seen_stop
);

  localparam [3:0] Stop = 4'b0001;  // 1
  localparam [3:0] AddressAndRw = 4'b0011;  // 3
  localparam [3:0] WriteBuffer = 4'b1001;  // 9
  localparam [3:0] Reset = 4'b1010;  // 10
  localparam [3:0] BadAddress = 4'b1011;  // 11

  localparam [7:0] ReadMask = 8'b0000_0000;
  localparam [7:0] WriteMask = 8'b0010_0000;  // 20

  reg [3:0] current_state;
  reg last_sda;
  reg [6:0] address;  // device address decoded from SDA line
  // Keeps track of how many bytes have been written or read.
  reg [3:0] byte_count;
  reg [7:0] transmitter_byte_buffer;
  reg [7:0] receiver_byte_buffer;
  reg read_request;
  reg transmitter_channel;
  reg ack_channel;
  reg [7:0] bad_address;

  reg r_output_selector_transmitter;  // 1 means transmitter, 0 means send an ack
  mux_2_1 output_mux (
      .one(transmitter_channel),
      .two(ack_channel),
      .selector(r_output_selector_transmitter),
      .out(write_channel)
  );

  reg byte_receiver_enable;
  byte_receiver byte_receiver (
      .clk(sck),
      .reset(reset),
      .enable(byte_receiver_enable),
      .in(read_channel),
      .out(receiver_byte_buffer)
  );

  reg byte_transmitter_enable;
  byte_transmitter byte_transmitter (
      .clk(sck),
      .reset(reset),
      .enable(byte_transmitter_enable),
      .in(transmitter_byte_buffer),
      .out(transmitter_channel)
  );

  reg [7:0] one_zero;
  reg [7:0] zero_one;

  // data and wires sent from an i2c request to be hashed.
  reg [7:0] to_hasher_write_data;
  logic to_hasher_write_inc;
  logic to_hasher_write_full;
  logic to_hasher_awfull;

  reg [7:0] to_hasher_read_data;
  logic to_hasher_read_inc;
  logic to_hasher_read_empty;
  logic to_hasher_aread_empty;

  async_fifo #(
      .DSIZE(8),
      .ASIZE(4)
  ) to_hasher_fifo (
      .wclk(sck),
      .wrst_n(~reset),
      .winc(to_hasher_write_inc),  // push data into the fifo from i2c write request
      .wdata(to_hasher_write_data),
      .wfull(to_hasher_write_full),
      .awfull(to_hasher_awfull),  // huh?
      .rclk(system_clk),
      .rrst_n(~reset),
      .rinc(to_hasher_read_inc),  // pop data from the fifo into hasher
      .rdata(to_hasher_read_data),  // read_* should be handled by hasher_fsm
      .rempty(to_hasher_read_empty),
      .arempty(to_hasher_aread_empty)
  );

  // data and wires sent from the hasher to an i2c response.
  reg [31:0] from_hasher_write_data;
  logic from_hasher_write_inc;
  logic from_hasher_write_full;
  logic from_hasher_awfull;

  reg [31:0] from_hasher_read_data;
  logic from_hasher_read_inc;
  logic from_hasher_read_empty;
  logic from_hasher_aread_empty;

  async_fifo #(
      .DSIZE(32),
      .ASIZE(4)
  ) from_hasher_fifo (
      .wclk(sck),
      .wrst_n(~reset),
      .winc(from_hasher_write_inc),  // push data onto fifo from hasher
      .wdata(from_hasher_write_data),
      .wfull(from_hasher_write_full),
      .awfull(from_hasher_awfull),  // huh?
      .rclk(system_clk),
      .rrst_n(~reset),
      .rinc(from_hasher_read_inc),  // pop data from fifo. this goes into the i2c response body
      .rdata(from_hasher_read_data),  // read_* should be handled by hasher_fsm
      .rempty(from_hasher_read_empty),
      .arempty(from_hasher_aread_empty)
  );

  always @(posedge sck) begin
    if (reset) begin
      r_output_selector_transmitter <= 1;
      read_request <= 0;
      direction <= ReadMask;
      current_state <= Stop;
      last_sda <= 0;
      byte_count <= 0;
      transmitter_byte_buffer <= 8'b0000_0000;
      byte_receiver_enable <= 0;
      byte_transmitter_enable <= 0;
      address <= 7'b000_0000;
      one_zero <= 8'b1010_1010;
      zero_one <= 8'b0101_0101;
      bad_address <= 8'b1100_1100;
    end else begin
      case (current_state)
        Stop: begin
          // transition from low to high over two clock cycles while in STOP.
          if (seen_start) begin
            current_state <= AddressAndRw;
          end else begin
            current_state <= Stop;
          end
        end
        AddressAndRw: begin
          byte_receiver_enable <= 1;
          if (byte_count < 8) begin
            byte_count <= byte_count + 1;
          end else begin
            direction <= WriteMask;
            r_output_selector_transmitter <= 0;
            ack_channel <= 1;  // sending ACK
            r_output_selector_transmitter <= 1;
            address <= receiver_byte_buffer[7:1];
            read_request <= receiver_byte_buffer[0];
            byte_receiver_enable <= 0;
            // NB: currently in our design, we ignore ACKs and NACKs from i2c transmittor.
            if (read_request) begin
              case (address)
                7'h71: begin  // fnv-1a hasher
                  // read 32 bits off last_hash_fifo and stream it back as 32 bits.
                  // There will be an ACK every 8 bits so how to handle that? switch direction, read ack, switch back?
                end
                7'h72: begin  // status byte of entries in `to_hash_fifo`
                  // send status byte back: how many entries in to_hash_fifo. we expect 0 all the time.
                  direction <= WriteMask;
                  // TODO: we should send how many entries are in the fifo
                  transmitter_byte_buffer <= 8'b1111_1111;
                  byte_transmitter_enable <= 1;
                  byte_count <= 1;
                  current_state <= WriteBuffer;

                end
                7'h2A: begin  // This is our ZeroOnePeriph peripheral.
                  direction <= WriteMask;
                  transmitter_byte_buffer <= zero_one;
                  byte_transmitter_enable <= 1;
                  byte_count <= 0;
                  current_state <= WriteBuffer;
                end
                7'h55: begin
                  direction <= WriteMask;
                  transmitter_byte_buffer <= one_zero;
                  byte_transmitter_enable <= 1;
                  byte_count <= 0;
                  current_state <= WriteBuffer;
                end
                default: begin  // Bad Address
                  direction <= WriteMask;
                  transmitter_byte_buffer <= bad_address;
                  byte_transmitter_enable <= 1;
                  byte_count <= 0;
                  current_state <= WriteBuffer;
                end
              endcase
            end else begin  // write address
              case (address)
                7'h71: begin  // fnv-1a hasher
                  // read byte, send ack, put byte onto to_hash_fifo
                end
                default: begin  // Bad Address
                  direction <= WriteMask;
                  transmitter_byte_buffer <= bad_address;
                  byte_transmitter_enable <= 1;
                  byte_count <= 0;
                  current_state <= WriteBuffer;
                  // byte_receiver feeds 8 bits into wdata, then wenc is set to 1;
                end
              endcase
            end
          end
        end
        WriteBuffer: begin
          if (byte_count == 7) begin
            byte_transmitter_enable <= 0;
            current_state <= Stop;
          end else begin
            byte_count <= byte_count + 1;
          end
        end
        BadAddress: begin
          current_state <= Stop;
        end
        Reset: begin
          address <= 7'b000_0000;
          current_state <= Stop;
        end
        default: current_state <= Stop;
      endcase
      last_sda <= read_channel;
    end
  end

`ifdef FORMAL
  always @(posedge clk) begin
  end
`endif

endmodule
`endif
