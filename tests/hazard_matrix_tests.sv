// Exhaustive hazard-matrix stress test for datapath_pipelined. Assembled
// via utils/assembler.py from four independent short programs (kept under
// instruction.sv's 64-word depth limit each), loaded and run as separate
// phases within one testbench: each phase overwrites instruction memory,
// nop-fills whatever's left over from the previous (longer) phase so a
// runaway PC can never fetch stale instructions, resets the whole DUT
// (clearing regfile and data memory), runs, and checks.
//
// ==== PHASE A: forwarding-distance matrix + chain + priority + x0 guard ====
//      addi x1, x0, 10
//      add  x2, x1, x0            # 0-gap rs1 (EX/MEM); x2=10
//      addi x3, x0, 11
//      addi x0, x0, 0
//      add  x4, x3, x0             # 1-gap rs1 (MEM/WB); x4=11
//      addi x5, x0, 12
//      add  x6, x0, x5              # 0-gap rs2; x6=12
//      addi x7, x0, 13
//      addi x0, x0, 0
//      add  x8, x0, x7               # 1-gap rs2; x8=13
//      addi x9, x0, 14
//      add  x10, x9, x9                # 0-gap rs1+rs2, same producer; x10=28
//      addi x11, x0, 15
//      addi x0, x0, 0
//      add  x12, x11, x11                # 1-gap rs1+rs2, same producer; x12=30
//      addi x13, x0, 1
//      addi x13, x0, 2                     # same dest written twice, back to back
//      add  x14, x13, x0                     # EX/MEM must beat stale MEM/WB; x14=2
//      add  x0, x1, x1                         # attempted write to x0 (=20), must
//                                               # be suppressed by the rd!=0 guards
//      add  x15, x0, x0                          # must read x0=0, not forward 20
//      addi x16, x0, 1                             # continuous chain: every add
//      add  x17, x16, x16                            # depends on the immediately
//      add  x18, x17, x17                              # preceding instruction for
//      add  x19, x18, x18                                # BOTH operands, 0-gap,
//      add  x20, x19, x19                                  # back-to-back, no idle
//      add  x21, x20, x20                                    # cycles: 1,2,4,8,16,
//      add  x22, x21, x21                                      # 32,64
//      addi x0, x0, 0
//      addi x0, x0, 0
//
// ==== PHASE B: back-to-back load-use stalls + fw_r2 at both distances ====
//      addi x1, x0, 7
//      sw   x1, 0(x0)               # mem[0] = 7
//      lw   x2, 0(x0)                 # x2 = 7
//      add  x3, x2, x0                 # STALL #1; x3 = 7
//      lw   x4, 0(x0)                    # x4 = 7 (second, independent load
//                                         # right after the first stall's consumer)
//      add  x5, x4, x0                     # STALL #2; x5 = 7 -- confirms stall
//                                           # self-clears and re-triggers cleanly
//      lw   x6, 0(x0)                        # x6 = 7
//      sw   x6, 9(x6)                          # STALL (rs1 addr AND rs2 data from
//                                               # the same load); addr=7+9=16=mem[4],
//                                               # data=7 -- 0-gap fw_r2, the path
//                                               # that was found missing earlier
//      lw   x7, 0(x0)                            # x7 = 7
//      addi x0, x0, 0                              # filler
//      sw   x7, 20(x0)                               # mem[5] = 7 -- 1-gap fw_r2
//
// ==== PHASE C: branch operand forwarding + branch/stall overlap ====
//      addi x1, x0, 6
//      addi x2, x0, 6
//      beq  x1, x2, branchC1        # x1: 1-gap fwd, x2: 0-gap fwd, same cycle
//      addi x3, x0, 999               # poison
//  branchC1:
//      addi x4, x0, 555                 # proof
//      addi x5, x0, 8
//      sw   x5, 24(x0)                    # mem[6] = 8
//      lw   x6, 24(x0)                      # x6 = 8
//      beq  x6, x5, branchC2                 # STALL: the stalled consumer IS the
//                                             # branch -- maximum stall/flush overlap
//      addi x7, x0, 999                        # poison
//  branchC2:
//      addi x8, x0, 555                          # proof
//      lw   x9, 24(x0)                             # x9 = 8
//      add  x10, x9, x0                              # STALL; x10 = 8
//      beq  x10, x5, branchC3                          # taken branch immediately
//                                                       # after a stall recovers,
//                                                       # not itself hazarded
//      addi x11, x0, 999                                 # poison
//  branchC3:
//      addi x12, x0, 555                                   # proof
//      beq  x0, x0, branchC4                                 # always taken
//      sw   x5, 28(x0)                                         # poison (mem[7])
//  branchC4:
//      lw   x13, 24(x0)                                          # x13 = 8, fetched
//                                                                 # right at the
//                                                                 # branch target
//      add  x14, x13, x0                                           # STALL right
//                                                                   # after the
//                                                                   # flush boundary
//
// ==== PHASE D: jal/jalr forwarding -- the link register, not the ALU result ====
//      jal  x1, jalTarget                # link = pc+4 = 4
//  jalTarget:
//      add  x2, x1, x0                     # 0-gap consumer of JAL's rd
//      jal  x3, jalTarget2                   # link = 12
//      addi x0, x0, 0
//  jalTarget2:
//      add  x4, x3, x0                         # 1-gap consumer of JAL's rd
//      jalr x6, jalrTarget(x0)                   # link = pc+4 = 24; target is
//                                                 # placed non-adjacent on purpose
//                                                 # so a wrong forwarded value can't
//                                                 # coincidentally look right
//      addi x20, x0, 999                           # dead code, jumped over
//  jalrTarget:
//      add  x7, x6, x0                               # 0-gap consumer of JALR's rd
//      jalr x8, jalrTarget2(x0)                        # link = 36
//      addi x21, x0, 999                                 # dead code, also serves
//                                                         # as the 1-gap filler
//  jalrTarget2:
//      add  x9, x8, x0                                     # 1-gap consumer of
//                                                           # JALR's rd
//
// ==== PHASE E: 0-gap LUI forwarding must not leak an unrelated register ====
// LUI's instr[19:15] field is part of its immediate encoding, not a real
// rs1 -- but the ALU still runs for every instruction and reads *some*
// register through that field. alu_result for a LUI is therefore
// garbage_register + correct_immediate, and only equals the correct
// immediate if that garbage register happens to hold 0. Forwarding must
// use the value LUI actually writes back (imm), not raw alu_result_exmem,
// or this garbage leaks into a 0-gap consumer.
//      addi x8, x0, 999          # poison the register LUI's instr[19:15]
//                                 # happens to decode to, for this immediate
//      lui  x1, 0x12345
//      add  x2, x1, x0             # 0-gap consumer; must be 0x12345000,
//                                   # not corrupted by x8's 999

module hazard_matrix_tests;
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

    task automatic load_phase(string path, int len);
        $readmemh(path, dut.imem.instructions);
        for (int i = len; i < 64; i++) begin
            dut.imem.instructions[i] = 32'h00000013; // nop-fill leftover from a longer phase
        end
    endtask

    task automatic run_phase(int cycles);
        reset = 1;
        repeat (2) @(posedge clk);
        // register.sv/data.sv no longer clear their storage on reset (that loop forced
        // FF-based synthesis instead of LUTRAM/BRAM inference); replicate the old
        // reset-clears-everything behavior here instead, since every phase in this
        // file expects a genuinely fresh DUT.
        for (int i = 0; i < 32; i++) dut.regfile.registers[i] = 0;
        for (int i = 0; i < 64; i++) dut.dmem.datas[i] = 0;
        reset = 0;
        repeat (cycles) @(posedge clk);
        #1;
    endtask

    initial begin
        // ---- PHASE A ----
        load_phase("tests/hazard_matrix_a.hex", 29);
        run_phase(60);
        $display("==== PHASE A: forwarding-distance matrix + chain + priority + x0 guard ====");
        check("0g-rs1p",1, dut.regfile.registers[1],  32'd10);
        check("0g-rs1", 2, dut.regfile.registers[2],  32'd10);
        check("1g-rs1p",3, dut.regfile.registers[3],  32'd11);
        check("1g-rs1", 4, dut.regfile.registers[4],  32'd11);
        check("0g-rs2p",5, dut.regfile.registers[5],  32'd12);
        check("0g-rs2", 6, dut.regfile.registers[6],  32'd12);
        check("1g-rs2p",7, dut.regfile.registers[7],  32'd13);
        check("1g-rs2", 8, dut.regfile.registers[8],  32'd13);
        check("0g-both",9, dut.regfile.registers[9],  32'd14);
        check("0g-both",10,dut.regfile.registers[10], 32'd28);
        check("1g-both",11,dut.regfile.registers[11], 32'd15);
        check("1g-both",12,dut.regfile.registers[12], 32'd30);
        check("prio",  13, dut.regfile.registers[13], 32'd2);
        check("prio",  14, dut.regfile.registers[14], 32'd2);
        check("x0-grd",0,  dut.regfile.registers[0],  32'd0);
        check("x0-grd",15, dut.regfile.registers[15], 32'd0);
        check("chain", 16, dut.regfile.registers[16], 32'd1);
        check("chain", 17, dut.regfile.registers[17], 32'd2);
        check("chain", 18, dut.regfile.registers[18], 32'd4);
        check("chain", 19, dut.regfile.registers[19], 32'd8);
        check("chain", 20, dut.regfile.registers[20], 32'd16);
        check("chain", 21, dut.regfile.registers[21], 32'd32);
        check("chain", 22, dut.regfile.registers[22], 32'd64);

        // ---- PHASE B ----
        load_phase("tests/hazard_matrix_b.hex", 13);
        run_phase(60);
        $display("==== PHASE B: back-to-back load-use stalls + fw_r2 at both distances ====");
        check("stall1",2, dut.regfile.registers[2], 32'd7);
        check("stall1",3, dut.regfile.registers[3], 32'd7);
        check("stall2",4, dut.regfile.registers[4], 32'd7);
        check("stall2",5, dut.regfile.registers[5], 32'd7);
        check_mem("0g-fwr2", 4, dut.dmem.datas[4], 32'd7);
        check_mem("1g-fwr2", 5, dut.dmem.datas[5], 32'd7);

        // ---- PHASE C ----
        load_phase("tests/hazard_matrix_c.hex", 22);
        run_phase(60);
        $display("==== PHASE C: branch operand forwarding + branch/stall overlap ====");
        check("br-psn",3,  dut.regfile.registers[3],  32'd0);
        check("br-prf",4,  dut.regfile.registers[4],  32'd555);
        check("olap-psn",7, dut.regfile.registers[7], 32'd0);
        check("olap-prf",8, dut.regfile.registers[8], 32'd555);
        check("olap-psn",11,dut.regfile.registers[11],32'd0);
        check("olap-prf",12,dut.regfile.registers[12],32'd555);
        check_mem("flush-psn", 7, dut.dmem.datas[7], 32'd0);
        check("flush-stall",14,dut.regfile.registers[14],32'd8);

        // ---- PHASE D ----
        load_phase("tests/hazard_matrix_d.hex", 13);
        run_phase(60);
        $display("==== PHASE D: jal/jalr forwarding (link register, not alu_result) ====");
        check("jal-0g",1, dut.regfile.registers[1], 32'd4);
        check("jal-0g",2, dut.regfile.registers[2], 32'd4);
        check("jal-1g",3, dut.regfile.registers[3], 32'd12);
        check("jal-1g",4, dut.regfile.registers[4], 32'd12);
        check("jalr-0g",6,dut.regfile.registers[6], 32'd24);
        check("jalr-0g",7,dut.regfile.registers[7], 32'd24);
        check("jalr-1g",8,dut.regfile.registers[8], 32'd36);
        check("jalr-1g",9,dut.regfile.registers[9], 32'd36);

        // ---- PHASE E ----
        load_phase("tests/hazard_matrix_e.hex", 5);
        run_phase(30);
        $display("==== PHASE E: 0-gap LUI forwarding must not leak an unrelated register ====");
        check("lui",   1, dut.regfile.registers[1], 32'h12345000);
        check("lui-0g",2, dut.regfile.registers[2], 32'h12345000);

        if (errors == 0) begin
            $display("---- ALL CHECKS PASSED ----");
        end
        else begin
            $display("---- %0d CHECK(S) FAILED ----", errors);
        end

        $finish;
    end
endmodule
