// Full-pipeline stress test for datapath_pipelined, assembled via
// utils/assembler.py from the source below (kept here since the hex alone
// isn't self-documenting). Every register write is checkpointed into data
// memory with an SW right after it's produced, so the whole test can run
// on a single small scratch register (x1, occasionally x2) without running
// out of the 32-register file, and results survive to the end of the run
// even though the register itself gets reused by later sections.
//
// One subtlety this test is deliberately built around: checkpointing a
// value with an SW on the very next instruction exercises EX/MEM store-data
// forwarding, which reads the *ALU result*, not what actually got written
// back to the register file. That can mask a real writeback bug (it does,
// for LUI -- see below), so every checkpoint that's meant to verify actual
// writeback correctness (not test forwarding itself) has at least one
// filler instruction before its SW.
//
//      # ---- seed ----
//      addi x1, x0, 5
//      sw   x1, 0(x0)                  # mem[0] = 5, source value for every
//                                       # load-use test below
//
//      # ---- control-flow + upper-immediate coverage ----
//      lui  x1, 0x12345
//      addi x0, x0, 0                  # filler: force this checkpoint through
//                                       # MEM/WB (real writeback), not EX/MEM
//                                       # store-data forwarding
//      sw   x1, 4(x0)                   # mem[1]: LUI result (expect 0x12345000)
//      auipc x1, 1
//      sw   x1, 8(x0)                    # mem[2]: AUIPC result
//      beq  x0, x0, cfA                   # always taken
//      sw   x1, 12(x0)                     # mem[3] poison: must be flushed (expect 0)
//  cfA:
//      addi x1, x0, 111
//      sw   x1, 16(x0)                      # mem[4] = 111: taken-branch proof
//      jal  x1, cfJT
//      sw   x1, 20(x0)                       # mem[5] poison: must be flushed (expect 0)
//  cfJT:
//      addi x1, x0, 333
//      sw   x1, 24(x0)                        # mem[6] = 333: JAL landed
//      jalr x1, cfJRT(x0)
//      sw   x1, 28(x0)                         # mem[7] poison: must be flushed (expect 0)
//  cfJRT:
//      addi x1, x0, 444
//      sw   x1, 32(x0)                          # mem[8] = 444: JALR landed
//
//      # ---- load-use hazard stress (needs correct stalling) ----
//      addi x1, x0, 123
//      sw   x1, 36(x0)                           # mem[9] = 123, payload for the
//                                                 # chained-load test below
//
//      lw   x1, 0(x0)                             # x1 = 5
//      sub  x2, x1, x0                             # STALL(rs1); x2 = 5
//      sw   x2, 40(x0)                              # mem[10]
//
//      lw   x1, 0(x0)                                # x1 = 5
//      or   x2, x0, x1                                # STALL(rs2); x2 = 5
//      sw   x2, 44(x0)                                 # mem[11]
//
//      lw   x1, 0(x0)                                   # x1 = 5 (address base)
//      lw   x2, 31(x1)                                   # STALL(rs1, chained load);
//                                                         # addr = 5+31 = 36 = mem[9];
//                                                         # x2 = 123
//      sw   x2, 48(x0)                                     # mem[12]
//      slt  x1, x0, x2                                      # STALL(rs1, back-to-back
//                                                            # with the load above);
//                                                            # x1 = (0 < 123) = 1
//      sw   x1, 52(x0)                                        # mem[13]
//
//      lw   x1, 0(x0)                                          # x1 = 5
//      sw   x1, 55(x1)                                          # STALL(rs1 addr AND
//                                                                # rs2 data, same load);
//                                                                # addr=5+55=60=mem[15],
//                                                                # data=5
//
//      addi x1, x0, 5                                            # stable reference = 5
//      lw   x2, 0(x0)                                             # x2 = 5
//      beq  x2, x1, hazBranchTaken                                 # STALL, then branch
//                                                                   # on the stalled value
//      sw   x2, 120(x0)                                             # mem[30] poison
//                                                                    # (expect 0)
//  hazBranchTaken:
//      addi x1, x0, 555
//      sw   x1, 64(x0)                                               # mem[16] proof
//
//      # ---- store-data forwarding (pure forwarding, no stall) ----
//      addi x1, x0, 77
//      sw   x1, 68(x0)                                                # mem[17]: EX/MEM
//                                                                      # -> store data
//      addi x1, x0, 88
//      addi x0, x0, 0                                                  # filler
//      sw   x1, 72(x0)                                                  # mem[18]: MEM/WB
//                                                                        # -> store data
//
//      # ---- forwarding priority (freshest value must win) ----
//      addi x1, x0, 1
//      addi x1, x0, 2
//      add  x2, x1, x0                                                    # x2 = 2, not 1
//      sw   x2, 76(x0)                                                     # mem[19]
//
//      # ---- branch operand forwarding, both sides ----
//      addi x1, x0, 9
//      addi x2, x0, 9
//      beq  x1, x2, hazBranch2Taken
//      sw   x1, 80(x0)                                                       # mem[20]
//                                                                             # poison
//  hazBranch2Taken:
//      addi x1, x0, 555
//      sw   x1, 84(x0)                                                         # mem[21]
//                                                                               # proof
//
//      # ---- flush + load-use stall interaction ----
//      beq  x0, x0, hazSkip                                                     # always
//                                                                                # taken
//      sw   x1, 88(x0)                                                           # mem[22]
//                                                                                 # poison
//  hazSkip:
//      lw   x1, 0(x0)                                                             # x1=5,
//                                                                    # fetched right at
//                                                                    # the branch target
//      sw   x1, 92(x0)                                              # STALL right after
//                                                                    # the flush boundary;
//                                                                    # mem[23] = 5
//
//      addi x0, x0, 0                                                # drain
//      addi x0, x0, 0

module complete_tests;
    logic clk, reset;

    datapath_pipelined dut (
        .clk(clk),
        .reset(reset)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    int errors = 0;

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
        $dumpfile("complete_tests.vcd");
        $dumpvars(0, complete_tests);

        $readmemh("tests/complete.hex", dut.imem.instructions);

        reset = 1;
        repeat (2) @(posedge clk);
        reset = 0;

        // 61 instructions plus ~6 load-use stall cycles and pipeline drain.
        // Generous margin.
        repeat (120) @(posedge clk);
        #1;

        $display("==== control-flow + upper-immediate coverage ====");
        check_mem("SEED",  0, dut.dmem.datas[0],  32'd5);
        check_mem("LUI",   1, dut.dmem.datas[1],  32'h12345000);
        check_mem("AUIPC", 2, dut.dmem.datas[2],  32'd4372);
        check_mem("BEQ-psn",3,dut.dmem.datas[3],  32'd0);
        check_mem("BEQ-prf",4,dut.dmem.datas[4],  32'd111);
        check_mem("JAL-psn",5,dut.dmem.datas[5],  32'd0);
        check_mem("JAL-prf",6,dut.dmem.datas[6],  32'd333);
        check_mem("JALR-psn",7,dut.dmem.datas[7], 32'd0);
        check_mem("JALR-prf",8,dut.dmem.datas[8], 32'd444);

        $display("==== load-use hazard stress (needs stalling) ====");
        check_mem("2a-rs1", 10, dut.dmem.datas[10], 32'd5);
        check_mem("2b-rs2", 11, dut.dmem.datas[11], 32'd5);
        check_mem("2d-ld",  12, dut.dmem.datas[12], 32'd123);
        check_mem("2g-ld2", 13, dut.dmem.datas[13], 32'd1);
        check_mem("2e-sw",  15, dut.dmem.datas[15], 32'd5);
        check_mem("2f-psn", 30, dut.dmem.datas[30], 32'd0);
        check_mem("2f-prf", 16, dut.dmem.datas[16], 32'd555);

        $display("==== store-data forwarding (no stall) ====");
        check_mem("3a-em", 17, dut.dmem.datas[17], 32'd77);
        check_mem("3b-mw", 18, dut.dmem.datas[18], 32'd88);

        $display("==== forwarding priority (EX/MEM beats MEM/WB) ====");
        check_mem("4-prio", 19, dut.dmem.datas[19], 32'd2);

        $display("==== branch operand forwarding, both sides ====");
        check_mem("5-psn", 20, dut.dmem.datas[20], 32'd0);
        check_mem("5-prf", 21, dut.dmem.datas[21], 32'd555);

        $display("==== flush + load-use stall interaction ====");
        check_mem("6-psn", 22, dut.dmem.datas[22], 32'd0);
        check_mem("6-res", 23, dut.dmem.datas[23], 32'd5);

        if (errors == 0) begin
            $display("---- ALL CHECKS PASSED ----");
        end
        else begin
            $display("---- %0d CHECK(S) FAILED ----", errors);
        end

        $finish;
    end
endmodule
