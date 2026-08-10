module datapath_ext_tb;
    logic clk, reset;

    datapath dut (
        .clk(clk),
        .reset(reset)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("datapath_ext.vcd");
        $dumpvars(0, datapath_ext_tb);

        $readmemh("program_extensions.hex", dut.imem.instructions);

        reset = 1;
        repeat (2) @(posedge clk);
        reset = 0;

        // 14 instructions actually execute (6 are skipped by JAL/JALR) —
        // generous margin
        repeat (25) @(posedge clk);
        #1;

        $display("---- final register state ----");
        $display("x1  (LUI)        = %0d / 0x%0h  (exp 0x12345000)", dut.regfile.registers[1], dut.regfile.registers[1]);
        $display("x2  (AUIPC)      = %0d / 0x%0h  (exp 0x00001004)", dut.regfile.registers[2], dut.regfile.registers[2]);
        $display("x3  (ADDI)       = %0d (exp 5)",   dut.regfile.registers[3]);
        $display("x4  (SLLI)       = %0d (exp 20)",  dut.regfile.registers[4]);
        $display("x5  (SRLI)       = %0d (exp 10)",  dut.regfile.registers[5]);
        $display("x6  (ADDI -8)    = 0x%0h (exp 0xfffffff8)", dut.regfile.registers[6]);
        $display("x7  (SRAI)       = 0x%0h (exp 0xfffffffc, sign-preserved)", dut.regfile.registers[7]);
        $display("x8  (JAL link)   = %0d (exp 44)",  dut.regfile.registers[8]);
        $display("x9  (skip proof) = %0d (exp 777, NOT 111/222/333/444/555/666)", dut.regfile.registers[9]);
        $display("x10 (ADDI 68)    = %0d (exp 68)",  dut.regfile.registers[10]);
        $display("x11 (JALR link)  = %0d (exp 64)",  dut.regfile.registers[11]);
        $display("x13 (SLL)        = %0d (exp 160)", dut.regfile.registers[13]);
        $display("x14 (SRL)        = %0d (exp 0)",   dut.regfile.registers[14]);
        $display("x15 (SRA)        = 0x%0h (exp 0xffffffff, i.e. -1)", dut.regfile.registers[15]);

        $finish;
    end
endmodule