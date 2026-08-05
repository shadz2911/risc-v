module datapath_tb;
    logic clk, reset;

    datapath dut (
        .clk(clk),
        .reset(reset)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("datapath.vcd");
        $dumpvars(0, datapath_tb);

        $readmemh("program.hex", dut.imem.instructions);

        reset = 1;
        repeat (2) @(posedge clk);
        reset = 0;

        repeat (15) @(posedge clk);
        #1;

        $display("---- final register state ----");
        $display("x1=%0d (exp 5)",  dut.regfile.registers[1]);
        $display("x2=%0d (exp 3)",  dut.regfile.registers[2]);
        $display("x3=%0d (exp 8)",  dut.regfile.registers[3]);
        $display("x4=%0d (exp 2)",  dut.regfile.registers[4]);
        $display("x5=%0d (exp 8)",  dut.regfile.registers[5]);
        $display("x6=%0d (exp 0, proves branch skipped this instruction)", dut.regfile.registers[6]);
        $display("x7=%0d (exp 7, proves execution resumed correctly after branch)", dut.regfile.registers[7]);
        $display("mem[0]=%0d (exp 8)", dut.dmem.datas[0]);

        $finish;
    end
endmodule