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

logic regw, memw, memr, branch, is_r;
alusrc_t alusrc;
memreg_t memreg;

// Control unit

control ctrl (
    .opcode(instr[6:0]),
    .regw(regw),
    .memw(memw),
    .memr(memr),
    .alusrc(alusrc),
    .branch(branch),
    .memreg(memreg),
    .is_r(is_r)
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

// ALU mux to choose between reg and imm

logic [31:0] alu_b;

alu_mux op_mux (
    .register(rdata2),
    .immediate(imm),
    .regimm(alusrc),
    .out(alu_b)
);

// ALU ctrl to choose which op

ops alu_op;

alu_control aluctrl (
    .is_r(is_r),
    .branch(branch),
    .funct3(instr[14:12]),
    .funct7(instr[31:25]),
    .op(alu_op)
);

// ALU unit to execute op

logic [31:0] alu_result;
logic zero;

alu alu_unit (
    .a(rdata1),
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

writeback_mux wb_mux (
    .alu(alu_result),
    .mem(mem_rdata),
    .memalu(memreg),
    .out(wdata)
);

// PC NEXT LOGIC

logic [31:0] pc_plus4_val;
logic [31:0] branch_target;

pc_plus4 pc4 (
    .pc(current_pc),
    .nextpc(pc_plus4_val)
);

branch_adder branch_add (
    .pc(current_pc),
    .imm(imm),
    .nextpc(branch_target)
);

pc_next_mux nextpc_mux (
    .pc_plus4(pc_plus4_val),
    .branch_target(branch_target),
    .branch(branch),
    .zero(zero),
    .pc_out(pc_next)
);

endmodule