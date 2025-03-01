`ifndef _MUX_2_1_
`define _MUX_2_1_

`default_nettype none


module mux_2_1 (
    input  logic one,
    input  logic two,
    input  logic selector,
    output logic out
);

  assign out = selector ? one : two;

endmodule
`endif
