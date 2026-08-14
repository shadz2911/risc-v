// Minimal smoke test for datapath_pipelined, assembled via utils/assembler.py
// from the source below (kept here since the hex alone isn't self-documenting):
//
//      addi x1, x0, 5
//      addi x2, x0, 3
//      addi x0, x0, 0          # nop
//      addi x0, x0, 0          # nop
//      addi x0, x0, 0          # nop
//      add  x3, x1, x2         # x3 = 8
//      addi x0, x0, 0          # nop
//      addi x0, x0, 0          # nop
//      addi x0, x0, 0          # nop
//      sw   x3, 0(x0)          # mem[0] = 8
//      lw   x22, 0(x0)         # x22 = 8
//      addi x0, x0, 0          # nop
//      addi x0, x0, 0          # nop
//      addi x0, x0, 0          # nop
//      add  x23, x22, x0       # x23 = 8
//      addi x0, x0, 0          # nop
//      addi x0, x0, 0          # nop
//      addi x0, x0, 0          # nop
//      beq  x1, x1, L1         # taken
//      addi x28, x0, 999       # poison: should be skipped
// L1:
//      addi x29, x0, 222       # proof: landed after taken branch
//      addi x0, x0, 0          # nop (drain)
//      addi x0, x0, 0          # nop (drain)
//      addi x0, x0, 0          # nop (drain)
//      addi x0, x0, 0          # nop (drain)
//
// This deliberately keeps a 3-instruction gap between every producer and its
// consumer (add/sw/lw), because forwarding and hazard/stall detection are not
// implemented yet: with a 5-stage pipeline and register writes only visible
// starting the cycle after WB, a dependent instruction needs to be at least
// 4 slots behind its producer to read the correct value.

module skeleton_tb;
    logic clk, reset;

    datapath_pipelined dut (
        .clk(clk),
        .reset(reset)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    int errors = 0;

    task automatic check(string name, int idx, logic [31:0] actual, logic [31:0] expected);
        if (actual !== expected) begin
            $display("FAIL %-6s x%0d = %0d (0x%0h)  expected %0d (0x%0h)",
                      name, idx, $signed(actual), actual, $signed(expected), expected);
            errors++;
        end
        else begin
            $display("pass %-6s x%0d = %0d (0x%0h)", name, idx, $signed(actual), actual);
        end
    endtask

    initial begin
        $dumpfile("skeleton.vcd");
        $dumpvars(0, skeleton_tb);

        $readmemh("tests/skeleton.hex", dut.imem.instructions);

        reset = 1;
        repeat (2) @(posedge clk);
        reset = 0;

        // 25 instructions, 5-stage pipeline, no stalls -> last instruction's
        // WB completes ~29 cycles after reset deasserts. Generous margin.
        repeat (40) @(posedge clk);
        #1;

        $display("---- final register state ----");
        check("ADDI", 1,  dut.regfile.registers[1],  32'd5);
        check("ADDI", 2,  dut.regfile.registers[2],  32'd3);
        check("ADD",  3,  dut.regfile.registers[3],  32'd8);
        check("LW",   22, dut.regfile.registers[22], 32'd8);
        check("ADD",  23, dut.regfile.registers[23], 32'd8);
        check("BEQ-T",28, dut.regfile.registers[28], 32'd0);
        check("BEQ-T",29, dut.regfile.registers[29], 32'd222);

        $display("mem[0] (SW x3) = %0d (exp 8)", dut.dmem.datas[0]);
        if (dut.dmem.datas[0] !== 32'd8) errors++;

        if (errors == 0) begin
            $display("---- ALL CHECKS PASSED ----");
        end
        else begin
            $display("---- %0d CHECK(S) FAILED ----", errors);
        end

        $finish;
    end
endmodule
