`ifndef _HASHER_FSM_
`define _HASHER_FSM_

`default_nettype none

// Fnv-1a works on an octet, so for each entry in the fifo, we set enable on the hasher and ensure
// that the fifo is worked with properly. This allows the hasher to focus only on hashing.
// Reads bytes from to_hash_fifo, waits to see 4 bytes, hashes those bytes,
// and places the results into the from_hash_fifo
module hasher_fsm (
    input logic clk,
    input logic reset,
    input logic [7:0] bits,  // should be read handle into fifo?
    output logic [7:0] data_to_hash  // this gets written to from_hash_fifo
);

  reg [3:0] current_state;

  logic hasher_enable;

  always @(posedge clk) begin
    if (reset) begin
      hasher_enable <= 0;
    end else begin
      data_to_hash  <= 8'b0;  // TODO: pop from the fifo
      hasher_enable <= 1;
    end
  end

endmodule
`endif
