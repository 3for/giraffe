// synthesis VERILOG_INPUT_VERSION SYSTEMVERILOG_2012
//
// NOTE: this file is autogenerated! Modifications will be lost.
//
// output layer, Verifier
// (C) 2016 Riad S. Wahby <rsw@cs.nyu.edu>

`include "simulator.v"
`include "field_arith_defs.v"
`include "vpintf_defs.v"
`include "verifier_compute_io.sv"
module verifier_output () ;

{0}
localparam nOutBits = $clog2(nOutputs);
localparam nValBits = nCopyBits + nOutBits;
localparam nOutputsRnd = 1 << nOutBits;
localparam nCopies = 1 << nCopyBits;
localparam nValues = 1 << nValBits;

reg clk, rstb;
reg [`F_NBITS-1:0] invals [(nCopies*nOutputs)-1:0];
wire [`F_NBITS-1:0] vals_in [nValues-1:0];

reg [`F_NBITS-1:0] z1 [nOutBits-1:0];
reg [`F_NBITS-1:0] z2 [nCopyBits-1:0];
wire [`F_NBITS-1:0] tau [nValBits-1:0];
reg [63:0] field_counts [5:0];

wire [`F_NBITS-1:0] mlext_out;

enum {{ ST_START, ST_RUN_ST, ST_RUN }} state_reg, state_next;
wire en_chi = state_reg == ST_RUN_ST;
wire ready;

genvar CopyNum;
genvar OutNum;
generate
    for (CopyNum = 0; CopyNum < nCopies; CopyNum = CopyNum + 1) begin
        localparam nOffset_out = CopyNum * nOutputsRnd;
        localparam nOffset_in = CopyNum * nOutputs;
        for (OutNum = 0; OutNum < nOutputs; OutNum = OutNum + 1) begin
            assign vals_in[nOffset_out + OutNum] = invals[nOffset_in + OutNum];
        end
        for (OutNum = nOutputs; OutNum < nOutputsRnd; OutNum = OutNum + 1) begin
            assign vals_in[nOffset_out + OutNum] = {{(`F_NBITS){{1'b0}}}};
        end
    end
    for (OutNum = 0; OutNum < nValBits; OutNum = OutNum + 1) begin
        if (OutNum < nOutBits) begin
            assign tau[OutNum] = z1[OutNum];
        end else begin
            assign tau[OutNum] = z2[OutNum - nOutBits];
        end
    end
endgenerate

integer i;
initial begin
    $dumpfile("verifier_output.fst");
    $dumpvars;
    if (defDebug == 1) begin
        for (i = 0; i < nValues; i = i + 1) begin
            $dumpvars(0, vals_in[i]);
        end
        for (i = 0; i < nValBits; i = i + 1) begin
            $dumpvars(0, tau[i]);
        end
    end
    $display("id #%d", $vpintf_init(`V_TYPE_OUT, 0));
    clk = 0;
    rstb = 1;
    state_reg = ST_START;
    #1 rstb = 0;
    #3 rstb = 1;
end

`ALWAYS_COMB begin
    state_next = state_reg;

    case (state_reg)
        ST_START: begin
            state_next = ST_RUN_ST;
        end

        ST_RUN_ST, ST_RUN: begin
            if (~en_chi & ready) begin
                state_next = ST_START;
            end else begin
                state_next = ST_RUN;
            end
        end
    endcase
end

`ALWAYS_FF @(clk) begin
    clk <= #1 ~clk;
end

`ALWAYS_FF @(posedge clk or negedge rstb) begin
    if (~rstb) begin
        state_reg <= ST_START;
    end else begin
        state_reg <= state_next;
        if (~en_chi & ready & (state_reg == ST_RUN)) begin
            $vpintf_send(`V_SEND_EXPECT, 1, mlext_out);
            $vpintf_send(`V_SEND_Z1, nOutBits, z1);
            $vpintf_send(`V_SEND_Z2, nCopyBits, z2);
            $f_getcnt(field_counts);
            $vpintf_send(`V_SEND_COUNTS, 6, field_counts);
            $f_rstcnt();
        end else if (state_reg == ST_START) begin
            if (defDebug == 1) $display("waiting (V_RECV_OUTPUTS)");
            $vpintf_recv(`V_RECV_OUTPUTS, nCopies * nOutputs, invals);
            if (defDebug == 1) $display("got (V_RECV_OUTPUTS)");

            randomize_z1z2();
        end
    end
end

verifier_compute_io
   #( .nValBits     (nValBits)
    , .nParBits     (nParBitsV)
    ) iOutput
    ( .clk          (clk)
    , .rstb         (rstb)
    , .en           (en_chi)
    , .tau          (tau)
    , .vals_in      (vals_in)
    , .mlext_out    (mlext_out)
    , .ready        (ready)
    );

task randomize_z1z2;
    integer i;
begin
    for (i = 0; i < nOutBits; i = i + 1) begin
        z1[i] = $f_rand();
    end
    for (i = 0; i < nCopyBits; i = i + 1) begin
        z2[i] = $f_rand();
    end
end
endtask

endmodule
