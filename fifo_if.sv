interface fifo_if #(parameter int WIDTH = 8, DEPTH = 8) (input logic clk);
    logic rst_n;
    logic wr_en;
    logic rd_en;
    logic [WIDTH-1:0] wr_data;
    logic [WIDTH-1:0] rd_data;
    logic full;
    logic empty;
    logic [$clog2(DEPTH+1)-1:0] used;
endinterface
