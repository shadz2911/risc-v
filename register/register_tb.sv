module register_tb;
    logic clk, reset;
    logic [4:0] waddr;
    logic [31:0] wdata;
    logic wenable;
    logic [4:0] raddr1, raddr2;
    logic [31:0] rdata1, rdata2;

    register dut (
        .clk(clk),
        .reset(reset),
        .waddr(waddr),
        .wdata(wdata),
        .wenable(wenable),
        .raddr1(raddr1),
        .raddr2(raddr2),
        .rdata1(rdata1),
        .rdata2(rdata2)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("register.vcd");
        $dumpvars(0, register_tb);

        reset = 1;
        wenable = 0;
        repeat (2) @(posedge clk);
        reset = 0;

        waddr = 15;
        wenable = 1;
        wdata = 125;
        @(posedge clk);
        #1;
        wenable = 0;

        raddr1 = 15;
        #1;
        $display("Read x15: expected 125 got=%0d", rdata1);

        waddr = 0;
        wenable = 1;
        wdata = 5;
        @(posedge clk);
        wenable = 0;

        raddr1 = 0;
        #1;
        $display("Read x0: expected 0 got=%0d", rdata1);

        raddr1 = 15;

        waddr = 15;
        wenable = 0;
        wdata = 5;
        @(posedge clk);
        $display("Read x15: expected 125 got=%0d", rdata1);

        raddr1 = 0;
        raddr2 = 15;
        #1;
        $display("Read x0 and x15: expected 0 and 125 got=%0d and %0d", rdata1, rdata2);

        $finish;
    end
endmodule
