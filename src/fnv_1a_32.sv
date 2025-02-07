`ifndef FNV_1A_32
`define FNV_1A_32

`default_nettype none
`timescale 1us / 100 ns

module fnv_1a_32 (
    input wire clk,
    input wire reset,
    input wire [31:0] in,
    output wire [31:0] out
);

  parameter [31:0] OFFSET_BASIS = 32'd2166136261;
  parameter [31:0] FNV_PRIME = 32'd16777619;

  reg [31:0] hash;

  /**
    * FNV-1a algorithm
    * ----
    * hash = offset_basis
    * for each octet_of_data to be hashed
    *   hash = hash xor octet_of_data
    *   hash = hash * FNV_prime
    * return hash
    **/

  always @(posedge clk) begin
    if (reset) hash <= OFFSET_BASIS;

    hash <= (hash ^ in) * FNV_PRIME;
  end

  assign out = hash;


  `ifdef FORMAL
     logic f_past_valid;

      initial begin
          f_past_valid = 0;
      reset = 1;
        end

  always_comb begin
               if (!f_past_valid) assume (reset);
                  end

            always @(posedge sck) begin
                  if (f_past_valid) begin
                          // Assert
                    // the
                    // basis
                    // of any
                    // hash
                    // function
                    //       assert
                    //       (in
                    //       !
                    //       = out);
                    //           end
                    //             end
                  end
            end
end
`endif
endmodule
`endif
