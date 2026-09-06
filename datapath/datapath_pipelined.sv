import control_pkg::*;
import alu_pkg::*;

module datapath_pipelined (
    input logic clk,
    input logic reset,
    output logic [3:0] leds
);

// THINGS TO DECLARE EARLY

logic [31:0] instr_ifid;
logic memr_idex;
logic [4:0] rd_idex, rs1_idex, rs2_idex;
logic valid_idex;
logic bubble;
logic regw_exmem, memw_exmem, memr_exmem;
memreg_t memregpc_exmem;
logic [31:0] rdata2_exmem, alu_result_exmem, pc_plus4_exmem, imm_exmem;
logic [4:0] rd_exmem;
logic valid_exmem;
logic regw_memwb;
logic [31:0] mem_rdata_memwb, alu_result_memwb, pc_plus4_memwb, imm_memwb;
logic [4:0] rd_memwb;
memreg_t memregpc_memwb;
logic valid_memwb;
logic [31:0] mem_rdata;

// PIPELINE CONTROL SIGNALS

logic stall;
logic flush;

hazard_detect hd (
    .memr_idex(memr_idex && valid_idex),
    .rd_idex(rd_idex),
    .instr(instr_ifid),

    .stall(stall)
);

// FETCH

// Setup pc and pc+4

logic [31:0] current_pc;
logic [31:0] pc_next;
logic [31:0] pc_plus4_val;
assign leds = current_pc [3:0] ;

pc pc_reg (
    .clk(clk),
    .reset(reset),
    .nextaddr(pc_next),
    .stall(stall),
    .currentaddr(current_pc)
);

pc_plus4 pc4 (
    .pc(current_pc),
    .nextpc(pc_plus4_val)
);

logic [31:0] instr;

// Instruction memory

instruction imem (
    .raddr(current_pc),
    .instr(instr)
);

// IF/ID pipeline register

logic [31:0] pc_plus4_ifid;
logic [31:0] current_pc_ifid;
logic valid_ifid;

if_id_reg if_id (
    .clk(clk),
    .reset(reset),
    .stall(stall),
    .flush(flush),

    .instr_in(instr),
    .pc_plus4_in(pc_plus4_val),
    .current_pc_in(current_pc),

    .instr_out(instr_ifid),
    .pc_plus4_out(pc_plus4_ifid),
    .current_pc_out(current_pc_ifid),
    .valid_out(valid_ifid)
);

// DECODE

logic regw, memw, memr, branch, is_rish;
alusrc_t alusrc;
memreg_t memregpc;
regpc_t regpc;
adderjalr_t use_br;

// Control unit

control ctrl (
    .opcode(instr_ifid[6:0]),

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
    .waddr(rd_memwb),
    .wdata(wdata),
    .wenable(regw_memwb && valid_memwb),
    .raddr1(instr_ifid[19:15]),
    .raddr2(instr_ifid[24:20]),
    .rdata1(rdata1),
    .rdata2(rdata2)
);

// Immediate generator

logic [31:0] imm;

imm_gen immgen (
    .instr(instr_ifid),
    .imm(imm)
);

// ID/EX pipeline register

logic regw_idex, memw_idex, branch_idex, is_rish_idex;
alusrc_t alusrc_idex;
memreg_t memregpc_idex;
regpc_t regpc_idex;
adderjalr_t use_br_idex;
logic [31:0] rdata1_idex, rdata2_idex;
logic [31:0] imm_idex;
logic [2:0] funct3_idex;
logic [6:0] funct7_idex;
logic [31:0] current_pc_idex, pc_plus4_idex;

id_ex_reg id_ex (
    .clk(clk),
    .reset(reset),
    .flush(bubble),
    .valid_in(valid_ifid),

    .regw_in(regw),
    .memw_in(memw),
    .memr_in(memr),
    .alusrc_in(alusrc),
    .branch_in(branch),
    .memregpc_in(memregpc),
    .regpc_in(regpc),
    .is_rish_in(is_rish),
    .use_br_in(use_br),
    .imm_in(imm),
    .funct3_in(instr_ifid[14:12]),
    .funct7_in(instr_ifid[31:25]),
    .rdata1_in(rdata1),
    .rdata2_in(rdata2),
    .current_pc_in(current_pc_ifid),
    .rd_in(instr_ifid[11:7]),
    .rs1_in(instr_ifid[19:15]),
    .rs2_in(instr_ifid[24:20]),
    .pc_plus4_in(pc_plus4_ifid),

    .regw_out(regw_idex),
    .memw_out(memw_idex),
    .memr_out(memr_idex),
    .alusrc_out(alusrc_idex),
    .branch_out(branch_idex),
    .memregpc_out(memregpc_idex),
    .regpc_out(regpc_idex),
    .is_rish_out(is_rish_idex),
    .use_br_out(use_br_idex),
    .imm_out(imm_idex),
    .funct3_out(funct3_idex),
    .funct7_out(funct7_idex),
    .rdata1_out(rdata1_idex),
    .rdata2_out(rdata2_idex),
    .current_pc_out(current_pc_idex),
    .rd_out(rd_idex),
    .rs1_out(rs1_idex),
    .rs2_out(rs2_idex),
    .pc_plus4_out(pc_plus4_idex),
    .valid_out(valid_idex)
);

// EXECUTE

// Choose between reg1 and pc

logic [31:0] alu_a_raw;

pc_reg_mux op_mux1 (
    .register(rdata1_idex),
    .pc(current_pc_idex),
    .regpc(regpc_idex),
    .out(alu_a_raw)
);

// ALU mux to choose between reg2 and imm

logic [31:0] alu_b_raw;

alu_mux op_mux2 (
    .register(rdata2_idex),
    .immediate(imm_idex),
    .regimm(alusrc_idex),
    .out(alu_b_raw)
);

// FORWARDING

// account for lui case where result is alu bypassed
logic [31:0] alu_result_exmem_fwd;

writeback_mux exmem_fwd_mux (
    .alu(alu_result_exmem),
    .mem(mem_rdata),
    .memalupc(memregpc_exmem),
    .pc_plus_4(pc_plus4_exmem),
    .imm(imm_exmem),
    .out(alu_result_exmem_fwd)
);

fw_t fw_a, fw_b, fw_r2;

forward_sel fw_sel (
    .regw_exmem(regw_exmem && valid_exmem),
    .regw_memwb(regw_memwb && valid_memwb),
    .rd_exmem(rd_exmem),
    .rd_memwb(rd_memwb),
    .rs1_idex(rs1_idex),
    .rs2_idex(rs2_idex),
    .regpc_idex(regpc_idex),
    .alusrc_idex(alusrc_idex),

    .fw_a(fw_a),
    .fw_b(fw_b),
    .fw_r2(fw_r2)
);

logic [31:0] alu_a, alu_b, rdata2_temp;

forward_mux fw_mux (
    .fw_a(fw_a),
    .fw_b(fw_b),
    .fw_r2(fw_r2),
    .alu_a_raw(alu_a_raw),
    .alu_b_raw(alu_b_raw),
    .alu_result_exmem(alu_result_exmem_fwd),
    .rdata2_idex(rdata2_idex),
    .wdata(wdata),
    
    .alu_a(alu_a),
    .alu_b(alu_b),
    .r2(rdata2_temp)
);

// ALU ctrl to choose which op

ops alu_op;

alu_control aluctrl (
    .is_rish(is_rish_idex),
    .branch(branch_idex),
    .use_br(use_br_idex),
    .alusrc(alusrc_idex),
    .funct3(funct3_idex),
    .funct7(funct7_idex),
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

logic beq;

branch_compare br_cmp (
    .a(alu_a),
    .b(alu_b),
    .beq(beq)
);

// Branch decision logic

logic [31:0] adder_target;
logic [31:0] branch_target;

branch_adder branch_add (
    .pc(current_pc_idex),
    .imm(imm_idex),
    .nextpc(adder_target)
);

jalr_adder_mux jalr_mux (
    .jalr(alu_result),
    .adder(adder_target),
    .use_br(use_br_idex),
    .branch_target(branch_target)
);

logic branch_taken;
assign branch_taken = valid_idex && ((memregpc_idex == use_pc_plus_4) || (branch_idex && beq));
assign flush = branch_taken;
assign bubble = branch_taken || stall;

pc_next_mux nextpc_mux (
    .pc_plus4(pc_plus4_val),
    .branch_target(branch_target),
    .branch_taken(branch_taken),
    .pc_out(pc_next)
);

// EX/MEM pipeline register

ex_mem_reg ex_mem (
    .clk(clk),
    .reset(reset),
    .valid_in(valid_idex),

    .regw_in(regw_idex),
    .memw_in(memw_idex),
    .memr_in(memr_idex),
    .memregpc_in(memregpc_idex),
    .alu_result_in(alu_result),
    .rdata2_in(rdata2_temp),
    .rd_in(rd_idex),
    .pc_plus4_in(pc_plus4_idex),
    .imm_in(imm_idex),

    .regw_out(regw_exmem),
    .memw_out(memw_exmem),
    .memr_out(memr_exmem),
    .memregpc_out(memregpc_exmem),
    .alu_result_out(alu_result_exmem),
    .rdata2_out(rdata2_exmem),
    .rd_out(rd_exmem),
    .pc_plus4_out(pc_plus4_exmem),
    .imm_out(imm_exmem),
    .valid_out(valid_exmem)
);

// MEMORY

data dmem (
    .clk(clk),
    .reset(reset),
    .addr(alu_result_exmem),
    .wdata(rdata2_exmem),
    .wenable(memw_exmem && valid_exmem),
    .rdata(mem_rdata)
);

// MEM/WB pipeline register

mem_wb_reg mem_wb (
    .clk(clk),
    .reset(reset),
    .valid_in(valid_exmem),

    .regw_in(regw_exmem),
    .memregpc_in(memregpc_exmem),
    .mem_rdata_in(mem_rdata),
    .alu_result_in(alu_result_exmem),
    .rd_in(rd_exmem),
    .pc_plus4_in(pc_plus4_exmem),
    .imm_in(imm_exmem),

    .regw_out(regw_memwb),
    .memregpc_out(memregpc_memwb),
    .mem_rdata_out(mem_rdata_memwb),
    .alu_result_out(alu_result_memwb),
    .rd_out(rd_memwb),
    .pc_plus4_out(pc_plus4_memwb),
    .imm_out(imm_memwb),
    .valid_out(valid_memwb)
);

// WRITEBACK

writeback_mux wb_mux (
    .alu(alu_result_memwb),
    .mem(mem_rdata_memwb),
    .memalupc(memregpc_memwb),
    .pc_plus_4(pc_plus4_memwb),
    .imm(imm_memwb),
    .out(wdata)
);

endmodule