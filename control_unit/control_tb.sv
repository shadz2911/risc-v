import control_pkg::*;
import alu_pkg::*;

module control_tb;
    // control module signals
    logic [6:0] opcode;
    logic regw, memw, memr, branch, is_r;
    alusrc_t alusrc;
    memreg_t memreg;

    // alu_control module signals
    logic [2:0] funct3;
    logic [6:0] funct7;
    ops op;

    control ctrl_dut (
        .opcode(opcode),
        .regw(regw),
        .memw(memw),
        .memr(memr),
        .alusrc(alusrc),
        .branch(branch),
        .memreg(memreg),
        .is_rish(is_rish)
    );

    alu_control alu_ctrl_dut (
        .is_rish(is_rish),
        .branch(branch),
        .funct3(funct3),
        .funct7(funct7),
        .op(op)
    );

    initial begin
        // -------------------------------------------------------------
        // R-type: ADD  (opcode=0110011, funct3=000, funct7=0000000)
        // -------------------------------------------------------------
        opcode = 7'b0110011;
        funct3 = 3'b000;
        funct7 = 7'b0000000;
        #1;
        $display("R-ADD:  regw=%0d(exp1) memw=%0d(exp0) memr=%0d(exp0) alusrc=%0d(exp0=use_reg) branch=%0d(exp0) memreg=%0d(exp0=use_alu) op=%0d(exp0=ADD)",
                  regw, memw, memr, alusrc, branch, memreg, op);

        // -------------------------------------------------------------
        // R-type: SUB  (funct3=000, funct7=0100000)
        // -------------------------------------------------------------
        funct7 = 7'b0100000;
        #1;
        $display("R-SUB:  op=%0d(exp SUB)", op);

        // -------------------------------------------------------------
        // R-type: AND (funct3=111)
        // -------------------------------------------------------------
        funct3 = 3'b111;
        funct7 = 7'b0000000;
        #1;
        $display("R-AND:  op=%0d(exp AND)", op);

        // -------------------------------------------------------------
        // R-type: OR (funct3=110)
        // -------------------------------------------------------------
        funct3 = 3'b110;
        #1;
        $display("R-OR:   op=%0d(exp OR)", op);

        // -------------------------------------------------------------
        // R-type: XOR (funct3=100)
        // -------------------------------------------------------------
        funct3 = 3'b100;
        #1;
        $display("R-XOR:  op=%0d(exp XOR)", op);

        // -------------------------------------------------------------
        // R-type: SLT (funct3=010)
        // -------------------------------------------------------------
        funct3 = 3'b010;
        #1;
        $display("R-SLT:  op=%0d(exp SLT)", op);

        // -------------------------------------------------------------
        // R-type: SLL (funct3=010)
        // -------------------------------------------------------------
        funct3 = 3'b001;
        #1;
        $display("R-SLL:  op=%0d(exp SLL)", op);

        // -------------------------------------------------------------
        // R-type: SRL (funct3=010)
        // -------------------------------------------------------------
        funct3 = 3'b101;
        funct7 = 7'b0000000;
        #1;
        $display("R-SRL:  op=%0d(exp SRL)", op);

        // -------------------------------------------------------------
        // R-type: SRA (funct3=010)
        // -------------------------------------------------------------
        funct7 = 7'b0100000;
        #1;
        $display("R-SRA:  op=%0d(exp SRA)", op);

        // -------------------------------------------------------------
        // ADDI (opcode=0010011)
        // -------------------------------------------------------------
        opcode = 7'b0010011;
        funct3 = 3'b000; // deliberately "wrong" value to prove is_r gates it out
        funct7 = 7'b0100000;
        #1;
        $display("ADDI:   regw=%0d(exp1) memw=%0d(exp0) memr=%0d(exp0) alusrc=%0d(exp1=use_imm) branch=%0d(exp0) memreg=%0d(exp0=use_alu) is_r=%0d(exp0) op=%0d(exp=ADD)",
                  regw, memw, memr, alusrc, branch, memreg, is_rish, op);

        // -------------------------------------------------------------
        // SLLI (opcode=0010011)
        // -------------------------------------------------------------
        opcode = 7'b0010011;
        funct3 = 3'b001; // deliberately "wrong" value to prove is_r gates it out
        funct7 = 7'b0100000;
        #1;
        $display("SLLI:   regw=%0d(exp1) memw=%0d(exp0) memr=%0d(exp0) alusrc=%0d(exp1=use_imm) branch=%0d(exp0) memreg=%0d(exp0=use_alu) is_r=%0d(exp0) op=%0d(exp=SLL)",
                  regw, memw, memr, alusrc, branch, memreg, is_rish, op);

        // -------------------------------------------------------------
        // LW (opcode=0000011)
        // -------------------------------------------------------------
        opcode = 7'b0000011;
        #1;
        $display("LW:     regw=%0d(exp1) memw=%0d(exp0) memr=%0d(exp1) alusrc=%0d(exp1=use_imm) branch=%0d(exp0) memreg=%0d(exp1=use_mem) op=%0d(exp=ADD)",
                  regw, memw, memr, alusrc, branch, memreg, op);

        // -------------------------------------------------------------
        // SW (opcode=0100011)
        // -------------------------------------------------------------
        opcode = 7'b0100011;
        #1;
        $display("SW:     regw=%0d(exp0) memw=%0d(exp1) memr=%0d(exp0) alusrc=%0d(exp1=use_imm) branch=%0d(exp0) op=%0d(exp=ADD)",
                  regw, memw, memr, alusrc, branch, op);

        // -------------------------------------------------------------
        // BEQ (opcode=1100011)
        // -------------------------------------------------------------
        opcode = 7'b1100011;
        #1;
        $display("BEQ:    regw=%0d(exp0) memw=%0d(exp0) memr=%0d(exp0) alusrc=%0d(exp0=use_reg) branch=%0d(exp1) op=%0d(exp=SUB)",
                  regw, memw, memr, alusrc, branch, op);

        // -------------------------------------------------------------
        // Invalid/unrecognized opcode -> default branch
        // -------------------------------------------------------------
        opcode = 7'b1111111;
        #1;
        $display("BAD OP: regw=%0d(exp0) memw=%0d(exp0) memr=%0d(exp0) branch=%0d(exp0) is_r=%0d(exp0)",
                  regw, memw, memr, branch, is_rish);

        $finish;
    end
endmodule