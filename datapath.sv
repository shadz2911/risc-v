import control_pkg::*;
import alu_pkg::*;

module datapath(
    input logic clk,
    input logic reset
);

// FETCH 

logic [31:0] current_pc;
logic [31:0] pc_next;

// Program counter

pc pc_reg (
    .clk(clk),
    .reset(reset),
    .nextaddr(pc_next),
    .currentaddr(current_pc)
);

logic [31:0] instr;

// Instruction memory

instruction imem (
    .raddr(current_pc),
    .instr(instr)
);

// DECODE

logic regw, memw, memr, branch, is_rish;
alusrc_t alusrc;
memreg_t memregpc;
regpc_t regpc;
adderjalr_t use_br;

// Control unit

control ctrl (
    .opcode(instr[6:0]),
    .regw(regw),
    .memw(memw),
    .memr(memr),
    .alusrc(alusrc),
    .branch(branch),
    .memregpc(memregpc),
    .regpc(regpc),
    .is_rish(is_rish),
    .use_br(use_br)
);

// Register file

logic [31:0] wdata, rdata1, rdata2;

register regfile (
    .clk(clk),
    .reset(reset),
    .waddr(instr[11:7]),
    .wdata(wdata),
    .wenable(regw),
    .raddr1(instr[19:15]),
    .raddr2(instr[24:20]),
    .rdata1(rdata1),
    .rdata2(rdata2)
);

// Immediate generator

logic [31:0] imm;

imm_gen immgen (
    .instr(instr),
    .imm(imm)
);

// EXECUTE

// Choose between reg1 and pc

logic [31:0] alu_a;

pc_reg_mux op_mux1 (
    .register(rdata1),
    .pc(current_pc),
    .regpc(regpc),
    .out(alu_a)
);

// ALU mux to choose between reg2 and imm

logic [31:0] alu_b;

alu_mux op_mux2 (
    .register(rdata2),
    .immediate(imm),
    .regimm(alusrc),
    .out(alu_b)
);

// ALU ctrl to choose which op

ops alu_op;

alu_control aluctrl (
    .is_rish(is_rish),
    .branch(branch),
    .funct3(instr[14:12]),
    .funct7(instr[31:25]),
    .op(alu_op)
);

// ALU unit to execute op

logic [31:0] alu_result;
logic zero;

alu alu_unit (
    .a(alu_a),
    .b(alu_b),
    .op(alu_op),
    .result(alu_result),
    .zero(zero)
);

// MEMORY

logic [31:0] mem_rdata;

data dmem (
    .clk(clk),
    .reset(reset),
    .addr(alu_result),
    .wdata(rdata2),
    .wenable(memw),
    .rdata(mem_rdata)
);

// WRITEBACK

// PC NEXT LOGIC

logic [31:0] pc_plus4_val;
logic [31:0] adder_target;
logic [31:0] branch_target;

pc_plus4 pc4 (
    .pc(current_pc),
    .nextpc(pc_plus4_val)
);

writeback_mux wb_mux (
    .alu(alu_result),
    .mem(mem_rdata),
    .memalupc(memregpc),
    .imm(imm),
    .pc_plus_4(pc_plus4_val),
    .out(wdata)
);

branch_adder branch_add (
    .pc(current_pc),
    .imm(imm),
    .nextpc(adder_target)
);

jalr_adder_mux jalr_mux (
    .jalr(alu_result),
    .adder(adder_target),
    .use_br(use_br),
    .branch_target(branch_target)
);

pc_next_mux nextpc_mux (
    .pc_plus4(pc_plus4_val),
    .branch_target(branch_target),
    .branch(branch),
    .zero(zero),
    .memalupc(memregpc),
    .pc_out(pc_next)
);

endmodule