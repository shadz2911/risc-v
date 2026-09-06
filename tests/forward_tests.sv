// Forwarding testbench for datapath_pipelined, assembled via utils/assembler.py
// from the source below (kept here since the hex alone isn't self-documenting).
// Stalling/load-use hazards are NOT covered here (not implemented yet) -- every
// hazard below is resolved purely by forwarding, with instruction spacing chosen
// so the two forwarding paths (EX/MEM and MEM/WB) are each exercised on their own.
//
//      # stable reference values, resolved via the plain register-file read
//      # (written long before they're consumed, so no forwarding involved)
//      addi x20, x0, 5
//      addi x21, x0, 8
//      addi x0, x0, 0
//      addi x0, x0, 0
//      addi x0, x0, 0
//
//      # 1: EX/MEM -> rs1 (adjacent instructions, 0-instruction gap)
//      addi x1, x0, 10
//      add  x2, x1, x0             # x2 = 10
//
//      # 2: EX/MEM -> rs2
//      addi x3, x0, 7
//      add  x4, x0, x3             # x4 = 7
//
//      # 3: MEM/WB -> rs1 (one unrelated instruction in between)
//      addi x5, x0, 15
//      addi x0, x0, 0
//      add  x6, x5, x0             # x6 = 15
//
//      # 4: MEM/WB -> rs2
//      addi x7, x0, 9
//      addi x0, x0, 0
//      add  x8, x0, x7             # x8 = 9
//
//      # 5: EX/MEM -> store data (sw's rs2 is the value, not the address --
//      #    alusrc=use_imm here, so this only works through the dedicated
//      #    fw_r2/rdata2 forwarding path, not the alu_b path)
//      addi x9, x0, 42
//      sw   x9, 0(x0)              # mem[0] = 42
//
//      # 6: MEM/WB -> store data
//      addi x10, x0, 99
//      addi x0, x0, 0
//      sw   x10, 4(x0)             # mem[1] = 99
//
//      # 7: MEM/WB -> consumer of a loaded value (the load's data is only
//      #    ready after MEM, so this is deliberately kept at 2-instruction
//      #    distance -- a 1-gap load-use here would need stalling)
//      lw   x16, 0(x0)             # x16 = mem[0] = 42
//      addi x0, x0, 0
//      add  x17, x16, x0           # x17 = 42
//
//      # 8: forwarding priority -- same destination written twice back to
//      #    back; the consumer must take the fresher EX/MEM value, not the
//      #    stale MEM/WB one
//      addi x14, x0, 1
//      addi x14, x0, 2
//      add  x15, x14, x0           # x15 = 2 (not 1)
//
//      # 9: EX/MEM -> branch rs1 operand, forwarded value decides whether
//      #    the branch is taken at all
//      addi x11, x0, 5
//      beq  x11, x20, branchA_taken
//      addi x25, x0, 999           # poison: only hit if forwarding is broken
//  branchA_taken:
//      addi x26, x0, 111
//
//      # 10: EX/MEM -> branch rs2 operand
//      addi x13, x0, 8
//      beq  x21, x13, branchB_taken
//      addi x27, x0, 999           # poison
//  branchB_taken:
//      addi x28, x0, 222
//
//      addi x0, x0, 0              # drain
//      addi x0, x0, 0
//      addi x0, x0, 0
//      addi x0, x0, 0

module forward_tests;
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

    task automatic check_mem(string name, int idx, logic [31:0] actual, logic [31:0] expected);
        if (actual !== expected) begin
            $display("FAIL %-6s mem[%0d] = %0d (0x%0h)  expected %0d (0x%0h)",
                      name, idx, $signed(actual), actual, $signed(expected), expected);
            errors++;
        end
        else begin
            $display("pass %-6s mem[%0d] = %0d (0x%0h)", name, idx, $signed(actual), actual);
        end
    endtask

    initial begin
        $dumpfile("forward_tests.vcd");
        $dumpvars(0, forward_tests);

        $readmemh("tests/forward.hex", dut.imem.instructions);

        reset = 1;
        repeat (2) @(posedge clk);
        // register.sv/data.sv no longer clear their storage on reset (that loop forced
        // FF-based synthesis instead of LUTRAM/BRAM inference); replicate the old
        // reset-clears-everything behavior here instead.
        for (int i = 0; i < 32; i++) dut.regfile.registers[i] = 0;
        for (int i = 0; i < 64; i++) dut.dmem.datas[i] = 0;
        reset = 0;

        // 38 instructions, 5-stage pipeline, no stalls -> last instruction's
        // WB completes ~42 cycles after reset deasserts. Generous margin.
        repeat (55) @(posedge clk);
        #1;

        $display("---- final register state ----");
        check("EXMEM", 2,  dut.regfile.registers[2],  32'd10);
        check("EXMEM", 4,  dut.regfile.registers[4],  32'd7);
        check("MEMWB", 6,  dut.regfile.registers[6],  32'd15);
        check("MEMWB", 8,  dut.regfile.registers[8],  32'd9);
        check("LWFWD", 17, dut.regfile.registers[17], 32'd42);
        check("PRIO",  15, dut.regfile.registers[15], 32'd2);
        check("POISON",25, dut.regfile.registers[25], 32'd0);
        check("BR-A",  26, dut.regfile.registers[26], 32'd111);
        check("POISON",27, dut.regfile.registers[27], 32'd0);
        check("BR-B",  28, dut.regfile.registers[28], 32'd222);

        $display("---- final data memory state ----");
        check_mem("SWFWD", 0, dut.dmem.datas[0], 32'd42);
        check_mem("SWFWD", 1, dut.dmem.datas[1], 32'd99);

        if (errors == 0) begin
            $display("---- ALL CHECKS PASSED ----");
        end
        else begin
            $display("---- %0d CHECK(S) FAILED ----", errors);
        end

        $finish;
    end
endmodule
