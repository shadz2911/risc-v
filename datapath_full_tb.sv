// Exercises every instruction currently implemented in the datapath:
//   R-type: ADD SUB AND OR XOR SLT SLL SRL SRA
//   I-type: ADDI ANDI ORI XORI SLTI SLLI SRLI SRAI
//   Memory: SW LW
//   Branch: BEQ (both taken and not-taken)
//   Upper immediate: LUI AUIPC
//   Jumps: JAL JALR
//
// x27-x31 are control-flow proof/poison registers rather than direct
// instruction results:
//   x27 - set to 111 only if the not-taken BEQ correctly fell through
//   x28 - poisoned to 999 if the taken BEQ incorrectly failed to skip it (expect 0)
//   x29 - set to 222 right after the taken-branch target, proving execution resumed there
//   x30 - accumulates 333 if JAL fails to skip its delay slot, 777 if JALR does the same (expect 0)
//   x31 - accumulates 444 on landing after JAL, 888 on landing after JALR (expect 1332 total)
//
// SLTU/SLTIU and the non-BEQ branches are known-unimplemented and intentionally
// excluded (see alu_control's default case).

module datapath_full_tb;
    logic clk, reset;

    datapath dut (
        .clk(clk),
        .reset(reset)
    );

    initial clk = 0;
    always #5 clk = ~clk;

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

    int errors = 0;

    initial begin
        $dumpfile("datapath_full.vcd");
        $dumpvars(0, datapath_full_tb);

        $readmemh("program_full.hex", dut.imem.instructions);

        reset = 1;
        repeat (2) @(posedge clk);
        reset = 0;

        // 36 instructions, 6 of them skipped by BEQ/JAL/JALR -> 30 actually execute.
        // generous margin.
        repeat (40) @(posedge clk);
        #1;

        $display("---- final register state ----");
        check("ADDI",  1, dut.regfile.registers[1],  32'd5);
        check("ADDI",  2, dut.regfile.registers[2],  32'd3);
        check("ADD",   3, dut.regfile.registers[3],  32'd8);
        check("SUB",   4, dut.regfile.registers[4],  32'd2);
        check("AND",   5, dut.regfile.registers[5],  32'd1);
        check("OR",    6, dut.regfile.registers[6],  32'd7);
        check("XOR",   7, dut.regfile.registers[7],  32'd6);
        check("SLT",   8, dut.regfile.registers[8],  32'd1);
        check("SLT",   9, dut.regfile.registers[9],  32'd0);
        check("ADDI", 10, dut.regfile.registers[10], 32'd2);
        check("SLL",  11, dut.regfile.registers[11], 32'd20);
        check("SRL",  12, dut.regfile.registers[12], 32'd1);
        check("ADDI", 13, dut.regfile.registers[13], 32'hFFFFFFF8);
        check("SRA",  14, dut.regfile.registers[14], 32'hFFFFFFFE);
        check("ANDI", 15, dut.regfile.registers[15], 32'd1);
        check("ORI",  16, dut.regfile.registers[16], 32'd7);
        check("XORI", 17, dut.regfile.registers[17], 32'd6);
        check("SLTI", 18, dut.regfile.registers[18], 32'd1);
        check("SLLI", 19, dut.regfile.registers[19], 32'd20);
        check("SRLI", 20, dut.regfile.registers[20], 32'd2);
        check("SRAI", 21, dut.regfile.registers[21], 32'hFFFFFFFC);
        check("LW",   22, dut.regfile.registers[22], 32'd5);
        check("LUI",  23, dut.regfile.registers[23], 32'h12345000);
        check("AUIPC",24, dut.regfile.registers[24], 32'h00001074);
        check("JAL",  25, dut.regfile.registers[25], 32'd124);
        check("JALR", 26, dut.regfile.registers[26], 32'd136);
        check("BEQ!T",27, dut.regfile.registers[27], 32'd111);
        check("BEQ-T",28, dut.regfile.registers[28], 32'd0);
        check("BEQ-T",29, dut.regfile.registers[29], 32'd222);
        check("JMP",  30, dut.regfile.registers[30], 32'd0);
        check("JMP",  31, dut.regfile.registers[31], 32'd1332);

        $display("mem[0] (SW x1) = %0d (exp 5)", dut.dmem.datas[0]);
        if (dut.dmem.datas[0] !== 32'd5) errors++;

        if (errors == 0) begin
            $display("---- ALL CHECKS PASSED ----");
        end
        else begin
            $display("---- %0d CHECK(S) FAILED ----", errors);
        end

        $finish;
    end
endmodule
