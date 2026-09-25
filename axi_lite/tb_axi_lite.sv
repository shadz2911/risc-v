module tb_axi_lite;

    localparam ADDR_WIDTH = 32;
    localparam DATA_WIDTH = 32;
    localparam MEM_WORDS  = 64;

    logic clk, rst;

    logic cpu_wr_req_valid;
    logic [ADDR_WIDTH-1:0] cpu_wr_req_addr;
    logic [DATA_WIDTH-1:0] cpu_wr_req_wdata;
    logic cpu_wr_req_ready;
    logic cpu_wr_resp_valid;
    logic cpu_wr_resp_error;

    logic cpu_rd_req_valid;
    logic [ADDR_WIDTH-1:0] cpu_rd_req_addr;
    logic cpu_rd_req_ready;
    logic cpu_rd_resp_valid;
    logic [DATA_WIDTH-1:0] cpu_rd_resp_rdata;
    logic cpu_rd_resp_error;

    logic [ADDR_WIDTH-1:0] m_axi_awaddr;
    logic [2:0] m_axi_awprot;
    logic m_axi_awvalid;
    logic m_axi_awready;

    logic [DATA_WIDTH-1:0] m_axi_wdata;
    logic m_axi_wvalid;
    logic m_axi_wready;

    logic [1:0] m_axi_bresp;
    logic m_axi_bvalid;
    logic m_axi_bready;

    logic [ADDR_WIDTH-1:0] m_axi_araddr;
    logic [2:0] m_axi_arprot;
    logic m_axi_arvalid;
    logic m_axi_arready;

    logic [DATA_WIDTH-1:0] m_axi_rdata;
    logic [1:0] m_axi_rresp;
    logic m_axi_rvalid;
    logic m_axi_rready;

    axi_lite_master #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .cpu_wr_req_valid(cpu_wr_req_valid),
        .cpu_wr_req_addr(cpu_wr_req_addr),
        .cpu_wr_req_wdata(cpu_wr_req_wdata),
        .cpu_wr_req_ready(cpu_wr_req_ready),
        .cpu_wr_resp_valid(cpu_wr_resp_valid),
        .cpu_wr_resp_error(cpu_wr_resp_error),
        .cpu_rd_req_valid(cpu_rd_req_valid),
        .cpu_rd_req_addr(cpu_rd_req_addr),
        .cpu_rd_req_ready(cpu_rd_req_ready),
        .cpu_rd_resp_valid(cpu_rd_resp_valid),
        .cpu_rd_resp_rdata(cpu_rd_resp_rdata),
        .cpu_rd_resp_error(cpu_rd_resp_error),
        .m_axi_awaddr(m_axi_awaddr),
        .m_axi_awprot(m_axi_awprot),
        .m_axi_awvalid(m_axi_awvalid),
        .m_axi_awready(m_axi_awready),
        .m_axi_wdata(m_axi_wdata),
        .m_axi_wvalid(m_axi_wvalid),
        .m_axi_wready(m_axi_wready),
        .m_axi_bresp(m_axi_bresp),
        .m_axi_bvalid(m_axi_bvalid),
        .m_axi_bready(m_axi_bready),
        .m_axi_araddr(m_axi_araddr),
        .m_axi_arprot(m_axi_arprot),
        .m_axi_arvalid(m_axi_arvalid),
        .m_axi_arready(m_axi_arready),
        .m_axi_rdata(m_axi_rdata),
        .m_axi_rresp(m_axi_rresp),
        .m_axi_rvalid(m_axi_rvalid),
        .m_axi_rready(m_axi_rready)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // ================= mini AXI-lite slave BFM =================
    logic [DATA_WIDTH-1:0] mem [0:MEM_WORDS-1];

    int  aw_ready_delay = 0;
    int  w_ready_delay  = 0;
    int  ar_ready_delay = 0;
    logic inject_write_error = 1'b0;
    logic inject_read_error  = 1'b0;

    logic b_fire, r_fire;
    assign b_fire = m_axi_bvalid && m_axi_bready;
    assign r_fire = m_axi_rvalid && m_axi_rready;

    // ---- AW channel ----
    int aw_delay_cnt;
    logic [ADDR_WIDTH-1:0] awaddr_captured;
    logic aw_captured;

    always_ff @(posedge clk) begin
        if (rst) begin
            aw_delay_cnt <= 0;
            aw_captured  <= 1'b0;
        end else begin
            if (!m_axi_awvalid) aw_delay_cnt <= aw_ready_delay;
            else if (aw_delay_cnt != 0) aw_delay_cnt <= aw_delay_cnt - 1;

            if (m_axi_awvalid && m_axi_awready) begin
                awaddr_captured <= m_axi_awaddr;
                aw_captured     <= 1'b1;
            end else if (b_fire) begin
                aw_captured <= 1'b0;
            end
        end
    end

    assign m_axi_awready = m_axi_awvalid && (aw_delay_cnt == 0);

    // ---- W channel ----
    int w_delay_cnt;
    logic [DATA_WIDTH-1:0] wdata_captured;
    logic w_captured;

    always_ff @(posedge clk) begin
        if (rst) begin
            w_delay_cnt <= 0;
            w_captured  <= 1'b0;
        end else begin
            if (!m_axi_wvalid) w_delay_cnt <= w_ready_delay;
            else if (w_delay_cnt != 0) w_delay_cnt <= w_delay_cnt - 1;

            if (m_axi_wvalid && m_axi_wready) begin
                wdata_captured <= m_axi_wdata;
                w_captured     <= 1'b1;
            end else if (b_fire) begin
                w_captured <= 1'b0;
            end
        end
    end

    assign m_axi_wready = m_axi_wvalid && (w_delay_cnt == 0);

    // ---- B channel ----
    always_ff @(posedge clk) begin
        if (rst) begin
            m_axi_bvalid <= 1'b0;
            m_axi_bresp  <= 2'b00;
        end else if (b_fire) begin
            m_axi_bvalid <= 1'b0;
        end else if (!m_axi_bvalid && aw_captured && w_captured) begin
            m_axi_bvalid <= 1'b1;
            m_axi_bresp  <= inject_write_error ? 2'b10 : 2'b00;
            mem[awaddr_captured[7:2]] <= wdata_captured;
        end
    end

    // ---- AR channel ----
    int ar_delay_cnt;
    logic [ADDR_WIDTH-1:0] araddr_captured;
    logic ar_captured;

    always_ff @(posedge clk) begin
        if (rst) begin
            ar_delay_cnt <= 0;
            ar_captured  <= 1'b0;
        end else begin
            if (!m_axi_arvalid) ar_delay_cnt <= ar_ready_delay;
            else if (ar_delay_cnt != 0) ar_delay_cnt <= ar_delay_cnt - 1;

            if (m_axi_arvalid && m_axi_arready) begin
                araddr_captured <= m_axi_araddr;
                ar_captured     <= 1'b1;
            end else if (r_fire) begin
                ar_captured <= 1'b0;
            end
        end
    end

    assign m_axi_arready = m_axi_arvalid && (ar_delay_cnt == 0);

    // ---- R channel ----
    always_ff @(posedge clk) begin
        if (rst) begin
            m_axi_rvalid <= 1'b0;
            m_axi_rresp  <= 2'b00;
            m_axi_rdata  <= '0;
        end else if (r_fire) begin
            m_axi_rvalid <= 1'b0;
        end else if (!m_axi_rvalid && ar_captured) begin
            m_axi_rvalid <= 1'b1;
            m_axi_rresp  <= inject_read_error ? 2'b10 : 2'b00;
            m_axi_rdata  <= mem[araddr_captured[7:2]];
        end
    end

    // ================= checking =================
    int errors = 0;

    task automatic check(string name, logic [DATA_WIDTH-1:0] actual, logic [DATA_WIDTH-1:0] expected);
        if (actual !== expected) begin
            $display("FAIL %-24s got 0x%0h expected 0x%0h", name, actual, expected);
            errors++;
        end else begin
            $display("pass %-24s = 0x%0h", name, actual);
        end
    endtask

    task automatic check_bool(string name, logic actual, logic expected);
        if (actual !== expected) begin
            $display("FAIL %-24s got %0b expected %0b", name, actual, expected);
            errors++;
        end else begin
            $display("pass %-24s = %0b", name, actual);
        end
    endtask

    // ================= cpu-side driver tasks =================
    task automatic cpu_write(input logic [ADDR_WIDTH-1:0] addr, input logic [DATA_WIDTH-1:0] data,
                             output logic error);
        cpu_wr_req_addr  <= addr;
        cpu_wr_req_wdata <= data;
        cpu_wr_req_valid <= 1'b1;
        @(posedge clk);
        while (!cpu_wr_req_ready) @(posedge clk);
        cpu_wr_req_valid <= 1'b0;
        while (!cpu_wr_resp_valid) @(posedge clk);
        error = cpu_wr_resp_error;
    endtask

    task automatic cpu_read(input logic [ADDR_WIDTH-1:0] addr,
                             output logic [DATA_WIDTH-1:0] data, output logic error);
        cpu_rd_req_addr  <= addr;
        cpu_rd_req_valid <= 1'b1;
        @(posedge clk);
        while (!cpu_rd_req_ready) @(posedge clk);
        cpu_rd_req_valid <= 1'b0;
        while (!cpu_rd_resp_valid) @(posedge clk);
        data  = cpu_rd_resp_rdata;
        error = cpu_rd_resp_error;
    endtask

    // ================= test sequence =================
    initial begin
        logic [DATA_WIDTH-1:0] rdata;
        logic err;

        $dumpfile("axi_lite.vcd");
        $dumpvars(0, tb_axi_lite);

        rst = 1;
        cpu_wr_req_valid = 1'b0;
        cpu_wr_req_addr  = '0;
        cpu_wr_req_wdata = '0;
        cpu_rd_req_valid = 1'b0;
        cpu_rd_req_addr  = '0;
        repeat (2) @(posedge clk);
        rst = 0;

        $display("---- basic write then readback ----");
        cpu_write(32'h0000_0000, 32'hDEAD_BEEF, err);
        check_bool("basic write error", err, 1'b0);
        cpu_read(32'h0000_0000, rdata, err);
        check("basic write-then-readback", rdata, 32'hDEAD_BEEF);
        check_bool("basic read error", err, 1'b0);

        $display("---- back-to-back requests (busy gating) ----");
        cpu_write(32'h0000_0004, 32'h1111_2222, err);
        cpu_write(32'h0000_0008, 32'h3333_4444, err);
        cpu_read(32'h0000_0004, rdata, err);
        check("back-to-back write A", rdata, 32'h1111_2222);
        cpu_read(32'h0000_0008, rdata, err);
        check("back-to-back write B", rdata, 32'h3333_4444);

        $display("---- delayed slave ready (valid held before ready arrives) ----");
        aw_ready_delay = 3;
        w_ready_delay  = 5;
        cpu_write(32'h0000_000C, 32'hAAAA_5555, err);
        aw_ready_delay = 0;
        w_ready_delay  = 0;
        cpu_read(32'h0000_000C, rdata, err);
        check("delayed-ready write", rdata, 32'hAAAA_5555);

        ar_ready_delay = 4;
        cpu_read(32'h0000_0000, rdata, err);
        ar_ready_delay = 0;
        check("delayed-ready read", rdata, 32'hDEAD_BEEF);

        $display("---- error response propagation ----");
        inject_write_error = 1'b1;
        cpu_write(32'h0000_0010, 32'hFFFF_FFFF, err);
        inject_write_error = 1'b0;
        check_bool("write error propagated", err, 1'b1);

        inject_read_error = 1'b1;
        cpu_read(32'h0000_0000, rdata, err);
        inject_read_error = 1'b0;
        check_bool("read error propagated", err, 1'b1);

        $display("---- concurrent read + write (independent channels) ----");
        aw_ready_delay = 8;
        w_ready_delay  = 8;
        fork
            begin
                logic werr;
                cpu_write(32'h0000_0014, 32'hCAFEF00D, werr);
                $display("t=%0t write completed", $time);
                check_bool("concurrent write error", werr, 1'b0);
            end
            begin
                logic [DATA_WIDTH-1:0] rd2;
                logic rerr2;
                cpu_read(32'h0000_0000, rd2, rerr2);
                $display("t=%0t read completed (while write still pending)", $time);
                check("concurrent read while write pending", rd2, 32'hDEAD_BEEF);
                check_bool("concurrent read error", rerr2, 1'b0);
            end
        join
        aw_ready_delay = 0;
        w_ready_delay  = 0;

        cpu_read(32'h0000_0014, rdata, err);
        check("concurrent write result readback", rdata, 32'hCAFEF00D);

        if (errors == 0) $display("---- ALL CHECKS PASSED ----");
        else $display("---- %0d CHECK(S) FAILED ----", errors);

        $finish;
    end

endmodule
