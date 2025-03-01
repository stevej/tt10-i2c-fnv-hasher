`ifndef _LZC_
`define _LZC_

`default_nettype none

module enc (
    input  wire [1:0] in,
    output reg  [1:0] out
);

  always_comb begin
    case (in[1:0])
      2'b00:   out = 2'b10;
      2'b01:   out = 2'b01;
      default: out = 2'b00;
    endcase
  end

endmodule  // enc

module lzc #(
    // bit width
    parameter bit [31:0] N  = 32,
    // internal parameters
    parameter bit [33:0] WI = 2 * N,
    parameter bit [31:0] WO = N + 1
) (
    input  wire  [WI-1:0] in,
    output logic [WO-1:0] out
);

  always_comb begin
    if (in[N-1+N] == 1'b0) begin
      out[WO-1]   = (in[N-1+N] & in[N-1]);
      out[WO-2]   = 1'b0;
      out[WO-3:0] = in[(2*N)-2 : N];
    end else begin
      out[WO-1]   = in[N-1+N] & in[N-1];
      out[WO-2]   = ~in[N-1];
      out[WO-3:0] = in[N-2 : 0];
    end
  end

`ifdef FORMAL
  always_comb begin
    cover (out == 32'h0);
  end
`endif

endmodule  // lzc
`endif  // _LZC_
