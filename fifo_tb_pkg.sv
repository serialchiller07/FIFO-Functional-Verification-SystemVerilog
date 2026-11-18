package fifo_tb_pkg;
    localparam int WIDTH = 8;
    localparam int DEPTH = 8;
    localparam int CYCLES = 500;

    class fifo_txn;
        rand bit wr_en;
        rand bit rd_en;
        rand bit [WIDTH-1:0] wr_data;
        constraint mix_c { {wr_en, rd_en} dist {2'b00:=10, 2'b01:=25,
                                               2'b10:=30, 2'b11:=35}; }
    endclass

    class fifo_sample;
        bit wr_en, rd_en, full, empty;
        bit [WIDTH-1:0] wr_data, rd_data;
        int unsigned used;
        int unsigned cycle_id;
    endclass

    class fifo_generator;
        mailbox #(fifo_txn) outbox;
        function new(mailbox #(fifo_txn) outbox);
            this.outbox = outbox;
        endfunction
        task run();
            fifo_txn t;
            for (int i = 0; i < CYCLES; i++) begin
                t = new();
                if (!t.randomize()) $fatal(1, "Transaction randomization failed");
                // Directed prefixes: fill, overflow, drain, underflow, then random.
                if (i < 4) begin t.wr_en = 0; t.rd_en = 0; end
                else if (i < 16) begin t.wr_en = 1; t.rd_en = 0; end
                else if (i < 24) begin t.wr_en = 1; t.rd_en = 0; end
                else if (i < 36) begin t.wr_en = 0; t.rd_en = 1; end
                else if (i < 44) begin t.wr_en = 0; t.rd_en = 1; end
                else if (i < 84) begin t.wr_en = 1; t.rd_en = 1; end
                outbox.put(t);
            end
        endtask
    endclass

    class fifo_driver;
        virtual fifo_if #(WIDTH, DEPTH) vif;
        mailbox #(fifo_txn) inbox;
        event started;
        function new(virtual fifo_if #(WIDTH, DEPTH) vif,
                     mailbox #(fifo_txn) inbox);
            this.vif = vif;
            this.inbox = inbox;
        endfunction
        task run();
            fifo_txn t;
            for (int i = 0; i < CYCLES; i++) begin
                inbox.get(t);
                @(negedge vif.clk);
                vif.wr_en = t.wr_en;
                vif.rd_en = t.rd_en;
                vif.wr_data = t.wr_data;
                if (i == 0) -> started;
            end
            @(negedge vif.clk);
            vif.wr_en = 0;
            vif.rd_en = 0;
        endtask
    endclass

    class fifo_monitor;
        virtual fifo_if #(WIDTH, DEPTH) vif;
        mailbox #(fifo_sample) outbox;
        event started;
        function new(virtual fifo_if #(WIDTH, DEPTH) vif,
                     mailbox #(fifo_sample) outbox, event started);
            this.vif = vif;
            this.outbox = outbox;
            this.started = started;
        endfunction
        task run();
            fifo_sample s;
            @started;
            for (int i = 0; i < CYCLES; i++) begin
                @(posedge vif.clk);
                // Requests and the combinational read data are sampled
                // before the DUT's nonblocking state updates at this edge.
                s = new();
                s.cycle_id = i;
                s.wr_en = vif.wr_en;
                s.rd_en = vif.rd_en;
                s.wr_data = vif.wr_data;
                s.rd_data = vif.rd_data;
                s.full = vif.full;
                s.empty = vif.empty;
                s.used = int'(vif.used);
                outbox.put(s);
            end
        endtask
    endclass

    class fifo_scoreboard;
        mailbox #(fifo_sample) inbox;
        bit [WIDTH-1:0] expected_q[$];
        int unsigned errors, checked, writes, reads, blocked_writes, blocked_reads;
        bit finished;

        covergroup fifo_cov with function sample(bit wr, bit rd, int unsigned occupancy);
            option.per_instance = 1;
            cp_action: coverpoint {wr,rd} {
                bins idle = {2'b00}; bins read_only = {2'b01};
                bins write_only = {2'b10}; bins both = {2'b11};
            }
            cp_level: coverpoint occupancy {
                bins zero = {0}; bins middle = {[1:DEPTH-1]}; bins maxed = {DEPTH};
            }
            action_x_level: cross cp_action, cp_level;
        endgroup

        function new(mailbox #(fifo_sample) inbox);
            this.inbox = inbox;
            fifo_cov = new();
        endfunction

        task run();
            fifo_sample s;
            bit accept_read, accept_write;
            bit [WIDTH-1:0] expected_data;
            for (int i = 0; i < CYCLES; i++) begin
                inbox.get(s);
                checked++;
                if (s.used != expected_q.size() ||
                    s.empty !== (expected_q.size() == 0) ||
                    s.full !== (expected_q.size() == DEPTH)) begin
                    $error("Cycle %0d STATUS mismatch: used=%0d expected=%0d full=%b empty=%b",
                        s.cycle_id, s.used, expected_q.size(), s.full, s.empty);
                    errors++;
                end
                fifo_cov.sample(s.wr_en, s.rd_en, expected_q.size());
                accept_read = s.rd_en && (expected_q.size() > 0);
                accept_write = s.wr_en && ((expected_q.size() < DEPTH) || accept_read);

                // Check the oldest expected word before changing the queue.
                if (accept_read) begin
                    expected_data = expected_q.pop_front();
                    if (s.rd_data !== expected_data) begin
                        $error("Cycle %0d DATA mismatch: actual=%02h expected=%02h",
                            s.cycle_id, s.rd_data, expected_data);
                        errors++;
                    end
                    reads++;
                end else if (s.rd_en) blocked_reads++;

                if (accept_write) begin
                    expected_q.push_back(s.wr_data);
                    writes++;
                end else if (s.wr_en) blocked_writes++;
            end
            finished = 1;
            $display("---- FIFO verification summary ----");
            $display("Cycles=%0d writes=%0d reads=%0d rejected_writes=%0d rejected_reads=%0d errors=%0d",
                     checked, writes, reads, blocked_writes, blocked_reads, errors);
            $display("Functional coverage = %0.2f%%", fifo_cov.get_inst_coverage());
            if (errors != 0) $fatal(1, "FAIL: scoreboard detected %0d errors", errors);
            $display("PASS: scoreboard checks completed");
        endtask
    endclass
endpackage
