module sync_fifo #(
    parameter int WIDTH = 8,
    parameter int DEPTH = 8,
    parameter int PTR_W = $clog2(DEPTH),
    parameter int CNT_W = $clog2(DEPTH + 1)
) (
    input  logic                 clk,
    input  logic                 rst_n,
    input  logic                 wr_en,
    input  logic                 rd_en,
    input  logic [WIDTH-1:0]     wr_data,
    output logic [WIDTH-1:0]     rd_data,
    output logic                 full,
    output logic                 empty,
    output logic [CNT_W-1:0]     used
);
    logic [WIDTH-1:0] storage [0:DEPTH-1];
    logic [PTR_W-1:0] wr_ptr, rd_ptr;
    logic take_wr, take_rd;

    assign full    = (used == DEPTH);
    assign empty   = (used == 0);
    assign take_rd = rd_en && !empty;
    // An accepted read makes room for a write on a full FIFO.
    assign take_wr = wr_en && (!full || take_rd);
    // First-word fall-through: valid only when !empty, before the active edge.
    assign rd_data = empty ? '0 : storage[rd_ptr];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= '0;
            rd_ptr <= '0;
            used   <= '0;
        end else begin
            if (take_wr) begin
                storage[wr_ptr] <= wr_data;
                wr_ptr <= (wr_ptr == DEPTH-1) ? '0 : wr_ptr + 1'b1;
            end
            if (take_rd)
                rd_ptr <= (rd_ptr == DEPTH-1) ? '0 : rd_ptr + 1'b1;

            case ({take_wr, take_rd})
                2'b10: used <= used + 1'b1;
                2'b01: used <= used - 1'b1;
                default: used <= used;
            endcase
        end
    end
endmodule
