module data_tb;
    logic clk, reset;
    logic [31:0] addr;
    logic [31:0] wdata;
    logic wenable;
    logic [31:0] rdata;

    data dut (
        .clk(clk),
        .reset(reset),
        .addr(addr),
        .wdata(wdata),
        .wenable(wenable),
        .rdata(rdata)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("data.vcd");
        $dumpvars(0, data_tb);

        reset = 1;
        wenable = 0;
        repeat (2) @(posedge clk);
        reset = 0;

        addr = 12;
        wenable = 1;
        wdata = 15;
        @(posedge clk);
        #1;
        wenable = 0;

        #1;

        $display("Read word 3: expected 15 got=%0d", rdata);

        wdata = 12;
        @(posedge clk);

        #1;

        $display("Read word 3: expected 15 got=%0d", rdata);

        addr = 8;
        wenable = 1;
        wdata = 10;
        @(posedge clk);
        #1;
        wenable = 0;

        #2;

        $display("Read word 2: expected 10 got=%0d", rdata);

        addr = 12;
        #1;

        $display("Read word 3: expected 15 got=%0d", rdata);

        #1;

        $finish;
    end
endmodule
