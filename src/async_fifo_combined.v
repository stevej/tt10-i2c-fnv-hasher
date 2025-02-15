//-----------------------------------------------------------------------------
// Copyright 2017 Damien Pretet ThotIP
// Copyright 2018 Julius Baxter
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//-----------------------------------------------------------------------------

`timescale 1 ns / 1 ps
`default_nettype none

module async_bidir_fifo

  #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4,
    parameter FALLTHROUGH   = "TRUE" // First word fall-through
    ) (
       input wire              a_clk,
       input wire              a_rst_n,
       input wire              a_winc,
       input wire [DSIZE-1:0]  a_wdata,
       input wire              a_rinc,
       output wire [DSIZE-1:0] a_rdata,
       output wire             a_full,
       output wire             a_afull,
       output wire             a_empty,
       output wire             a_aempty,
       input wire              a_dir, // dir = 1: this side is writing, dir = 0: this side is reading


       input wire              b_clk,
       input wire              b_rst_n,
       input wire              b_winc,
       input wire [DSIZE-1:0]  b_wdata,
       input wire              b_rinc,
       output wire [DSIZE-1:0] b_rdata,
       output wire             b_full,
       output wire             b_afull,
       output wire             b_empty,
       output wire             b_aempty,
       input wire              b_dir // dir = 1: this side is writing, dir = 0: this side is reading
       );

  wire [ASIZE-1:0]             a_addr, b_addr;
  wire [ASIZE-1:0]             a_waddr, a_raddr, b_waddr, b_raddr;
  wire [  ASIZE:0]             a_wptr, b_rptr, a2b_wptr, b2a_rptr;
  wire [  ASIZE:0]             a_rptr, b_wptr, a2b_rptr, b2a_wptr;

  assign a_addr = a_dir ? a_waddr : a_raddr;
  assign b_addr = b_dir ? b_waddr : b_raddr;

  //////////////////////////////////////////////////////////////////////////////
  // A-side logic
  //////////////////////////////////////////////////////////////////////////////

  // Sync b write pointer to a domain
  sync_ptr #(ASIZE)
  sync_b2a_wptr
    (
     .dest_clk   (a_clk),
     .dest_rst_n (a_rst_n),
     .src_ptr    (b_wptr),
     .dest_ptr   (b2a_wptr)
     );

  // Sync b read pointer to a domain
  sync_ptr #(ASIZE)
  sync_b2a_rptr
    (
     .dest_clk   (a_clk),
     .dest_rst_n (a_rst_n),
     .src_ptr    (b_rptr),
     .dest_ptr   (b2a_rptr)
     );

  // The module handling the write requests
  // outputs valid when dir == 0 (a is writing)
  wptr_full #(ASIZE)
  a_wptr_inst
    (
     .wclk     (a_clk),
     .wrst_n   (a_rst_n),
     .winc     (a_winc),
     .wq2_rptr (b2a_rptr),
     .awfull   (a_afull),
     .wfull    (a_full),
     .waddr    (a_waddr),
     .wptr     (a_wptr)
     );

  // dir == 1 read pointer on a side calculation
  rptr_empty #(ASIZE)
  a_rptr_inst
    (
     .rclk     (a_clk),
     .rrst_n   (a_rst_n),
     .rinc     (a_rinc),
     .rq2_wptr (b2a_wptr),
     .arempty  (a_aempty),
     .rempty   (a_empty),
     .raddr    (a_raddr),
     .rptr     (a_rptr)
     );

  //////////////////////////////////////////////////////////////////////////////
  // B-side logic
  //////////////////////////////////////////////////////////////////////////////

  // Sync a write pointer to b domain
  sync_ptr #(ASIZE)
  sync_a2b_wptr
    (
     .dest_clk   (b_clk),
     .dest_rst_n (b_rst_n),
     .src_ptr    (a_wptr),
     .dest_ptr   (a2b_wptr)
     );

  // Sync a read pointer to b domain
  sync_ptr #(ASIZE)
  sync_a2b_rptr
    (
     .dest_clk   (b_clk),
     .dest_rst_n (b_rst_n),
     .src_ptr    (a_rptr),
     .dest_ptr   (a2b_rptr)
     );

  // The module handling the write requests
  // outputs valid when dir == 0 (b is writing)
  wptr_full #(ASIZE)
  b_wptr_inst
    (
     .wclk     (b_clk),
     .wrst_n   (b_rst_n),
     .winc     (b_winc),
     .wq2_rptr (a2b_rptr),
     .awfull   (b_afull),
     .wfull    (b_full),
     .waddr    (b_waddr),
     .wptr     (b_wptr)
     );

  // dir == 1 read pointer on b side calculation
  rptr_empty #(ASIZE)
  b_rptr_inst
    (
     .rclk     (b_clk),
     .rrst_n   (b_rst_n),
     .rinc     (b_rinc),
     .rq2_wptr (a2b_wptr),
     .arempty  (b_aempty),
     .rempty   (b_empty),
     .raddr    (b_raddr),
     .rptr     (b_rptr)
     );

  //////////////////////////////////////////////////////////////////////////////
  // FIFO RAM
  //////////////////////////////////////////////////////////////////////////////

  fifomem_dp #(DSIZE, ASIZE, FALLTHROUGH)
  fifomem_dp
    (
     .a_clk   (a_clk),
     .a_wdata (a_wdata),
     .a_rdata (a_rdata),
     .a_addr  (a_addr),
     .a_rinc  (a_rinc & !a_dir),
     .a_winc  (a_winc & a_dir),

     .b_clk   (b_clk),
     .b_wdata (b_wdata),
     .b_rdata (b_rdata),
     .b_addr  (b_addr),
     .b_rinc  (b_rinc & !b_dir),
     .b_winc  (b_winc & b_dir)
     );



endmodule

`resetall
//-----------------------------------------------------------------------------
// Copyright 2017 Damien Pretet ThotIP
// Copyright 2018 Julius Baxter
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//-----------------------------------------------------------------------------

`timescale 1 ns / 1 ps
`default_nettype none

module async_bidir_ramif_fifo

  #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4,
    parameter FALLTHROUGH   = "FALSE" // First word fall-through, not sure it can be disabled for this
    ) (
       input wire              a_clk,
       input wire              a_rst_n,
       input wire              a_winc,
       input wire [DSIZE-1:0]  a_wdata,
       input wire              a_rinc,
       output wire [DSIZE-1:0] a_rdata,
       output wire             a_full,
       output wire             a_afull,
       output wire             a_empty,
       output wire             a_aempty,
       input wire              a_dir, // dir = 1: this side is writing, dir = 0: this side is reading


       input wire              b_clk,
       input wire              b_rst_n,
       input wire              b_winc,
       input wire [DSIZE-1:0]  b_wdata,
       input wire              b_rinc,
       output wire [DSIZE-1:0] b_rdata,
       output wire             b_full,
       output wire             b_afull,
       output wire             b_empty,
       output wire             b_aempty,
       input wire              b_dir, // dir = 1: this side is writing, dir = 0: this side is reading

       // Dual-port RAM interface
       output wire             o_ram_a_clk,
       output wire [DSIZE-1:0] o_ram_a_wdata,
       input wire [DSIZE-1:0]  i_ram_a_rdata,
       output wire [ASIZE-1:0] o_ram_a_addr,
       output wire             o_ram_a_rinc,
       output wire             o_ram_a_winc,
       output wire             o_ram_b_clk,
       output wire [DSIZE-1:0] o_ram_b_wdata,
       input wire [DSIZE-1:0]  i_ram_b_rdata,
       output wire [ASIZE-1:0] o_ram_b_addr,
       output wire             o_ram_b_rinc,
       output wire             o_ram_b_winc
       );

  wire [ASIZE-1:0]             a_addr, b_addr;
  wire [ASIZE-1:0]             a_waddr, a_raddr, b_waddr, b_raddr;
  wire [  ASIZE:0]             a_wptr, b_rptr, a2b_wptr, b2a_rptr;
  wire [  ASIZE:0]             a_rptr, b_wptr, a2b_rptr, b2a_wptr;

  assign a_addr = a_dir ? a_waddr : a_raddr;
  assign b_addr = b_dir ? b_waddr : b_raddr;

  //////////////////////////////////////////////////////////////////////////////
  // A-side logic
  //////////////////////////////////////////////////////////////////////////////

  // Sync b write pointer to a domain
  sync_ptr #(ASIZE)
  sync_b2a_wptr
    (
     .dest_clk   (a_clk),
     .dest_rst_n (a_rst_n),
     .src_ptr    (b_wptr),
     .dest_ptr   (b2a_wptr)
     );

  // Sync b read pointer to a domain
  sync_ptr #(ASIZE)
  sync_b2a_rptr
    (
     .dest_clk   (a_clk),
     .dest_rst_n (a_rst_n),
     .src_ptr    (b_rptr),
     .dest_ptr   (b2a_rptr)
     );

  // The module handling the write requests
  // outputs valid when dir == 0 (a is writing)
  wptr_full #(ASIZE)
  a_wptr_inst
    (
     .wclk     (a_clk),
     .wrst_n   (a_rst_n),
     .winc     (a_winc),
     .wq2_rptr (b2a_rptr),
     .awfull   (a_afull),
     .wfull    (a_full),
     .waddr    (a_waddr),
     .wptr     (a_wptr)
     );

  // dir == 1 read pointer on a side calculation
  rptr_empty #(ASIZE)
  a_rptr_inst
    (
     .rclk     (a_clk),
     .rrst_n   (a_rst_n),
     .rinc     (a_rinc),
     .rq2_wptr (b2a_wptr),
     .arempty  (a_aempty),
     .rempty   (a_empty),
     .raddr    (a_raddr),
     .rptr     (a_rptr)
     );

  //////////////////////////////////////////////////////////////////////////////
  // B-side logic
  //////////////////////////////////////////////////////////////////////////////

  // Sync a write pointer to b domain
  sync_ptr #(ASIZE)
  sync_a2b_wptr
    (
     .dest_clk   (b_clk),
     .dest_rst_n (b_rst_n),
     .src_ptr    (a_wptr),
     .dest_ptr   (a2b_wptr)
     );

  // Sync a read pointer to b domain
  sync_ptr #(ASIZE)
  sync_a2b_rptr
    (
     .dest_clk   (b_clk),
     .dest_rst_n (b_rst_n),
     .src_ptr    (a_rptr),
     .dest_ptr   (a2b_rptr)
     );

  // The module handling the write requests
  // outputs valid when dir == 0 (b is writing)
  wptr_full #(ASIZE)
  b_wptr_inst
    (
     .wclk     (b_clk),
     .wrst_n   (b_rst_n),
     .winc     (b_winc),
     .wq2_rptr (a2b_rptr),
     .awfull   (b_afull),
     .wfull    (b_full),
     .waddr    (b_waddr),
     .wptr     (b_wptr)
     );

  // dir == 1 read pointer on b side calculation
  rptr_empty #(ASIZE)
  b_rptr_inst
    (
     .rclk     (b_clk),
     .rrst_n   (b_rst_n),
     .rinc     (b_rinc),
     .rq2_wptr (a2b_wptr),
     .arempty  (b_aempty),
     .rempty   (b_empty),
     .raddr    (b_raddr),
     .rptr     (b_rptr)
     );

  //////////////////////////////////////////////////////////////////////////////
  // FIFO RAM interface
  //////////////////////////////////////////////////////////////////////////////
  
  assign o_ram_a_clk   = a_clk;
  assign o_ram_a_wdata = a_wdata;
  assign a_rdata  = i_ram_a_rdata;
  assign o_ram_a_addr  = a_addr;
  assign o_ram_a_rinc  = a_rinc & !a_dir;
  assign o_ram_a_winc  = a_winc & a_dir;
  assign o_ram_b_clk   = b_clk;
  assign o_ram_b_wdata = b_wdata;
  assign b_rdata  = i_ram_b_rdata;
  assign o_ram_b_addr  = b_addr;
  assign o_ram_b_rinc  = b_rinc & !b_dir;
  assign o_ram_b_winc  = b_winc & b_dir;

endmodule

`resetall
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

module async_fifo

    #(
        parameter DSIZE = 8,
        parameter ASIZE = 4,
        parameter FALLTHROUGH = "TRUE" // First word fall-through without latency
    )(
        input  wire             wclk,
        input  wire             wrst_n,
        input  wire             winc,
        input  wire [DSIZE-1:0] wdata,
        output wire             wfull,
        output wire             awfull,
        input  wire             rclk,
        input  wire             rrst_n,
        input  wire             rinc,
        output wire [DSIZE-1:0] rdata,
        output wire             rempty,
        output wire             arempty
    );

    wire [ASIZE-1:0] waddr, raddr;
    wire [ASIZE  :0] wptr, rptr, wq2_rptr, rq2_wptr;

    // The module synchronizing the read point
    // from read to write domain
    sync_r2w
    #(ASIZE)
    sync_r2w (
    .wq2_rptr (wq2_rptr),
    .rptr     (rptr),
    .wclk     (wclk),
    .wrst_n   (wrst_n)
    );

    // The module synchronizing the write point
    // from write to read domain
    sync_w2r
    #(ASIZE)
    sync_w2r (
    .rq2_wptr (rq2_wptr),
    .wptr     (wptr),
    .rclk     (rclk),
    .rrst_n   (rrst_n)
    );

    // The module handling the write requests
    wptr_full
    #(ASIZE)
    wptr_full (
    .awfull   (awfull),
    .wfull    (wfull),
    .waddr    (waddr),
    .wptr     (wptr),
    .wq2_rptr (wq2_rptr),
    .winc     (winc),
    .wclk     (wclk),
    .wrst_n   (wrst_n)
    );

    // The DC-RAM
    fifomem
    #(DSIZE, ASIZE, FALLTHROUGH)
    fifomem (
    .rclken (rinc),
    .rclk   (rclk),
    .rdata  (rdata),
    .wdata  (wdata),
    .waddr  (waddr),
    .raddr  (raddr),
    .wclken (winc),
    .wfull  (wfull),
    .wclk   (wclk)
    );

    // The module handling read requests
    rptr_empty
    #(ASIZE)
    rptr_empty (
    .arempty  (arempty),
    .rempty   (rempty),
    .raddr    (raddr),
    .rptr     (rptr),
    .rq2_wptr (rq2_wptr),
    .rinc     (rinc),
    .rclk     (rclk),
    .rrst_n   (rrst_n)
    );

endmodule

`resetall
//-----------------------------------------------------------------------------
// Copyright 2017 Damien Pretet ThotIP
// Copyright 2018 Julius Baxter
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//-----------------------------------------------------------------------------

`timescale 1 ns / 1 ps
`default_nettype none

module fifomem_dp

    #(
        parameter  DATASIZE     = 8,      // Memory data word width
        parameter  ADDRSIZE     = 4,      // Number of mem address bits
        parameter  FALLTHROUGH  = "TRUE"  // First word fall-through
    ) (
        input  wire                a_clk,
        input  wire [DATASIZE-1:0] a_wdata,
        output wire [DATASIZE-1:0] a_rdata,
        input  wire [ADDRSIZE-1:0] a_addr,
        input  wire                a_rinc,
        input  wire                a_winc,

        input  wire                b_clk,
        input  wire [DATASIZE-1:0] b_wdata,
        output wire [DATASIZE-1:0] b_rdata,
        input  wire [ADDRSIZE-1:0] b_addr,
        input  wire                b_rinc,
        input  wire                b_winc
    );

    reg [DATASIZE-1:0] a_rdata_r;
    reg [DATASIZE-1:0] b_rdata_r;

    generate

        localparam DEPTH = 1<<ADDRSIZE;
        reg [DATASIZE-1:0] mem [0:DEPTH-1];

        if (FALLTHROUGH == "TRUE") begin : fallthrough

            always @(posedge a_clk)
                if (a_winc)
                    mem[a_addr] <= a_wdata;

            assign a_rdata  = mem[a_addr];

            always @(posedge b_clk)
                if (b_winc)
                    mem[b_addr] <= b_wdata;

            assign b_rdata = mem[b_addr];

        end else begin : registered

            wire a_en = a_rinc | a_winc;

            always @(posedge a_clk)
                if (a_en) begin
                    if (a_winc)
                        mem[a_addr] <= a_wdata;
                    a_rdata_r <= mem[a_addr];
                end

            assign a_rdata = a_rdata_r;

            wire b_en = b_rinc | b_winc;

            always @(posedge b_clk)
                if (b_en) begin
                    if (b_winc)
                        mem[b_addr] <= b_wdata;
                    b_rdata_r <= mem[b_addr];
                end

            assign b_rdata = b_rdata_r;

        end // block: registered
    endgenerate


endmodule

`resetall
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

module fifomem

    #(
        parameter  DATASIZE = 8,    // Memory data word width
        parameter  ADDRSIZE = 4,    // Number of mem address bits
        parameter  FALLTHROUGH = "TRUE" // First word fall-through
    ) (
        input  wire                wclk,
        input  wire                wclken,
        input  wire [ADDRSIZE-1:0] waddr,
        input  wire [DATASIZE-1:0] wdata,
        input  wire                wfull,
        input  wire                rclk,
        input  wire                rclken,
        input  wire [ADDRSIZE-1:0] raddr,
        output wire [DATASIZE-1:0] rdata
    );

    localparam DEPTH = 1<<ADDRSIZE;

    reg [DATASIZE-1:0] mem [0:DEPTH-1];
    reg [DATASIZE-1:0] rdata_r;

    always @(posedge wclk) begin
        if (wclken && !wfull)
            mem[waddr] <= wdata;
    end

    generate
        if (FALLTHROUGH == "TRUE")
        begin : fallthrough
            assign rdata = mem[raddr];
        end
        else
        begin : registered_read
            always @(posedge rclk) begin
                if (rclken)
                    rdata_r <= mem[raddr];
            end
            assign rdata = rdata_r;
        end
    endgenerate

endmodule

`resetall
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

module rptr_empty

    #(
    parameter ADDRSIZE = 4
    )(
    input  wire                rclk,
    input  wire                rrst_n,
    input  wire                rinc,
    input  wire [ADDRSIZE  :0] rq2_wptr,
    output reg                 rempty,
    output reg                 arempty,
    output wire [ADDRSIZE-1:0] raddr,
    output reg  [ADDRSIZE  :0] rptr
    );

    reg  [ADDRSIZE:0] rbin;
    wire [ADDRSIZE:0] rgraynext, rbinnext, rgraynextm1;
    wire              arempty_val, rempty_val;

    //-------------------
    // GRAYSTYLE2 pointer
    //-------------------
    always @(posedge rclk or negedge rrst_n) begin

        if (!rrst_n)
            {rbin, rptr} <= 0;
        else
            {rbin, rptr} <= {rbinnext, rgraynext};

    end

    // Memory read-address pointer (okay to use binary to address memory)
    assign raddr     = rbin[ADDRSIZE-1:0];
    assign rbinnext  = rbin + (rinc & ~rempty);
    assign rgraynext = (rbinnext >> 1) ^ rbinnext;
    assign rgraynextm1 = ((rbinnext + 1'b1) >> 1) ^ (rbinnext + 1'b1);

    //---------------------------------------------------------------
    // FIFO empty when the next rptr == synchronized wptr or on reset
    //---------------------------------------------------------------
    assign rempty_val = (rgraynext == rq2_wptr);
    assign arempty_val = (rgraynextm1 == rq2_wptr);

    always @ (posedge rclk or negedge rrst_n) begin

        if (!rrst_n) begin
            arempty <= 1'b0;
            rempty <= 1'b1;
        end
        else begin
            arempty <= arempty_val;
            rempty <= rempty_val;
        end

    end

endmodule

`resetall
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

module sync_ptr

    #(
    parameter ASIZE = 4
    )(
    input  wire              dest_clk,
    input  wire              dest_rst_n,
    input  wire [ASIZE:0] src_ptr,
    output reg  [ASIZE:0] dest_ptr
    );

    reg [ASIZE:0] ptr_x;

    always @(posedge dest_clk or negedge dest_rst_n) begin

        if (!dest_rst_n)
            {dest_ptr,ptr_x} <= 0;
        else
            {dest_ptr,ptr_x} <= {ptr_x,src_ptr};
    end

endmodule

`resetall
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

module sync_r2w

    #(
    parameter ASIZE = 4
    )(
    input  wire              wclk,
    input  wire              wrst_n,
    input  wire [ASIZE:0] rptr,
    output reg  [ASIZE:0] wq2_rptr
    );

    reg [ASIZE:0] wq1_rptr;

    always @(posedge wclk or negedge wrst_n) begin

        if (!wrst_n)
            {wq2_rptr,wq1_rptr} <= 0;
        else
            {wq2_rptr,wq1_rptr} <= {wq1_rptr,rptr};

    end

endmodule

`resetall
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

module sync_w2r

    #(
    parameter ASIZE = 4
    )(
    input  wire              rclk,
    input  wire              rrst_n,
    output reg  [ASIZE:0] rq2_wptr,
    input  wire [ASIZE:0] wptr
    );

    reg [ASIZE:0] rq1_wptr;

    always @(posedge rclk or negedge rrst_n) begin

        if (!rrst_n)
            {rq2_wptr,rq1_wptr} <= 0;
        else
            {rq2_wptr,rq1_wptr} <= {rq1_wptr,wptr};

    end

endmodule

`resetall
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

module wptr_full

	#(
		parameter ADDRSIZE = 4
	)(
		input  wire                wclk,
		input  wire                wrst_n,
		input  wire                winc,
		input  wire [ADDRSIZE  :0] wq2_rptr,
		output reg                 wfull,
		output reg                 awfull,
		output wire [ADDRSIZE-1:0] waddr,
		output reg  [ADDRSIZE  :0] wptr
	);

    reg  [ADDRSIZE:0] wbin;
    wire [ADDRSIZE:0] wgraynext, wbinnext, wgraynextp1;
    wire              awfull_val, wfull_val;

	// GRAYSTYLE2 pointer
	always @(posedge wclk or negedge wrst_n) begin

		if (!wrst_n)
			{wbin, wptr} <= 0;
		else
			{wbin, wptr} <= {wbinnext, wgraynext};

	end

    // Memory write-address pointer (okay to use binary to address memory)
    assign waddr = wbin[ADDRSIZE-1:0];
    assign wbinnext  = wbin + (winc & ~wfull);
    assign wgraynext = (wbinnext >> 1) ^ wbinnext;
    assign wgraynextp1 = ((wbinnext + 1'b1) >> 1) ^ (wbinnext + 1'b1);

    //------------------------------------------------------------------
    // Simplified version of the three necessary full-tests:
    // assign wfull_val=((wgnext[ADDRSIZE] !=wq2_rptr[ADDRSIZE] ) &&
    //                   (wgnext[ADDRSIZE-1]  !=wq2_rptr[ADDRSIZE-1]) &&
    // (wgnext[ADDRSIZE-2:0]==wq2_rptr[ADDRSIZE-2:0]));
    //------------------------------------------------------------------

     assign wfull_val = (wgraynext == {~wq2_rptr[ADDRSIZE:ADDRSIZE-1],wq2_rptr[ADDRSIZE-2:0]});
     assign awfull_val = (wgraynextp1 == {~wq2_rptr[ADDRSIZE:ADDRSIZE-1],wq2_rptr[ADDRSIZE-2:0]});

     always @(posedge wclk or negedge wrst_n) begin

        if (!wrst_n) begin
            awfull <= 1'b0;
            wfull  <= 1'b0;
        end else begin
            awfull <= awfull_val;
            wfull  <= wfull_val;
        end
    end

endmodule

`resetall
