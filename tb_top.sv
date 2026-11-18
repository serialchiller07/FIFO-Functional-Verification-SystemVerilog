`timescale 1ns/1ps
module tb_top;
    import fifo_tb_pkg::*;
    logic clk = 0;
    always #5 clk = ~clk;
    fifo_if #(WIDTH, DEPTH) bus(clk);

    sync_fifo #(.WIDTH(WIDTH), .DEPTH(DEPTH)) dut (
        .clk(clk), .rst_n(bus.rst_n), .wr_en(bus.wr_en), .rd_en(bus.rd_en),
        .wr_data(bus.wr_data), .rd_data(bus.rd_data),
        .full(bus.full), .empty(bus.empty), .used(bus.used)
    );
    fifo_properties #(.DEPTH(DEPTH)) properties (
        .clk(clk), .rst_n(bus.rst_n), .wr_en(bus.wr_en), .rd_en(bus.rd_en),
        .full(bus.full), .empty(bus.empty), .used(bus.used)
    );

    mailbox #(fifo_txn) stimulus = new();
    mailbox #(fifo_sample) observations = new();
    fifo_generator gen;
    fifo_driver drv;
    fifo_monitor mon;
    fifo_scoreboard sb;

    initial begin
        bus.rst_n = 0;
        bus.wr_en = 0;
        bus.rd_en = 0;
        bus.wr_data = '0;
        repeat (4) @(negedge clk);
        bus.rst_n = 1;
        gen = new(stimulus);
        drv = new(bus, stimulus);
        mon = new(bus, observations, drv.started);
        sb = new(observations);
        fork
            gen.run();
            drv.run();
            mon.run();
            sb.run();
        join
        $finish;
    end
    initial begin
        #100000;
        $fatal(1, "FAIL: testbench timeout");
    end
endmodule
