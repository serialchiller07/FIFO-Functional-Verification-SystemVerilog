module fifo_properties #(
    parameter int DEPTH = 8,
    parameter int CNT_W = $clog2(DEPTH+1)
) (
    input logic clk, rst_n, wr_en, rd_en, full, empty,
    input logic [CNT_W-1:0] used
);
    // Immediate checks sampled before sequential nonblocking updates.
    ap_count_range: assert property (@(posedge clk) disable iff (!rst_n)
        used <= DEPTH) else $fatal(1, "FIFO occupancy exceeded DEPTH");
    ap_empty_flag: assert property (@(posedge clk) disable iff (!rst_n)
        empty == (used == 0)) else $fatal(1, "Empty flag inconsistent");
    ap_full_flag: assert property (@(posedge clk) disable iff (!rst_n)
        full == (used == DEPTH)) else $fatal(1, "Full flag inconsistent");
    ap_flags: assert property (@(posedge clk) disable iff (!rst_n)
        !(full && empty)) else $fatal(1, "Full and empty asserted together");
endmodule
