import uvm_pkg::*;
`include "uvm_macros.svh"

`uvm_analysis_imp_decl(_prog)
`uvm_analysis_imp_decl(_result)

class instr_scoreboard extends uvm_scoreboard;

`uvm_component_utils(instr_scoreboard)

uvm_analysis_imp_prog #(instr_transaction, instr_scoreboard) prog_export;
uvm_analysis_imp_result #(instr_result, instr_scoreboard) result_export;

instr_transaction loaded_program [64];
instr_result expected_q [$];
int retire_count = 0;

// Spike's PC resets every lap (jumps back to _start); the DUT's real PC
// just keeps counting up while only its imem fetch address wraps. So
// AUIPC/JAL/JALR diverge once any address retires twice
bit addr_seen [64];
bit wrapped = 0;

// Manual coverage (hit-set per value) instead of a covergroup -- XSim's
// per-instance vs. aggregate semantics didn't match the LRM default.
bit opcode_seen  [bit [6:0]];
bit funct3_seen  [bit [2:0]];
bit rd_x0_seen   [bit];
bit rs1_x0_seen  [bit];
bit rs2_x0_seen  [bit];

function new(string name, uvm_component parent);
    super.new(name, parent);
    prog_export = new("prog_export", this);
    result_export = new("result_export", this);
endfunction

function void write_prog(instr_transaction t);
    loaded_program[t.addr] = t;

    opcode_seen[t.opcode] = 1;
    funct3_seen[t.funct3] = 1;
    rd_x0_seen[t.rd == 0] = 1;
    rs1_x0_seen[t.rs1 == 0] = 1;
    rs2_x0_seen[t.rs2 == 0] = 1;
endfunction

// Dumps loaded_program[] as .word directives for Spike, rewriting LW/SW's
// x0 base to x31 (set up by the trailer after the real 64 words).
task dump_for_spike(string path);
    int fd;
    instr_transaction spike_copy;

    fd = $fopen(path, "w");

    $fwrite(fd, ".text\n.global _start\n_start:\n");

    for (int i = 0; i < 64; i++) begin
        spike_copy = instr_transaction::type_id::create("spike_copy");
        spike_copy.copy(loaded_program[i]);
        if (spike_copy.opcode == 7'b0000011 || spike_copy.opcode == 7'b0100011)
            spike_copy.rs1 = 31;
        $fwrite(fd, ".word 0x%08h\n", spike_copy.encode());
    end

    $fwrite(fd, "lui x31, 0x80018\n"); // middle of the 0x80010000:0x10000 region -- headroom for negative LW/SW offsets
    $fwrite(fd, "jal x0, _start\n");

    $fclose(fd);
endtask

// Runs the loaded program through Spike and parses its --log-commits
// trace into expected_q, one entry per retired instruction, in order.
task run_spike(string base_path, int max_instructions);
    string s_file, o_file, elf_file, trace_file, cmd;
    int status;
    int fd;
    string line;
    int core_id, priv, reg_idx, n;
    bit [31:0] pc, instr, regval, memaddr, memdata;
    instr_result exp;

    s_file     = {base_path, ".s"};
    o_file     = {base_path, ".o"};
    elf_file   = {base_path, ".elf"};
    trace_file = {base_path, ".trace"};

    dump_for_spike(s_file);

    cmd = $sformatf("wsl bash /home/shady_wsl/fpga_ws/risc-v/uvm/golden_model/wsl_run.sh riscv64-unknown-elf-as -march=rv32i -mabi=ilp32 -o %s %s", o_file, s_file);
    status = $system(cmd);
    if (status != 0)
        `uvm_error(get_type_name(), $sformatf("assembler failed (%0d): %s", status, cmd))

    cmd = $sformatf("wsl bash /home/shady_wsl/fpga_ws/risc-v/uvm/golden_model/wsl_run.sh riscv64-unknown-elf-ld -m elf32lriscv -T /home/shady_wsl/fpga_ws/risc-v/uvm/golden_model/spike_link.ld -o %s %s", elf_file, o_file);
    status = $system(cmd);
    if (status != 0)
        `uvm_error(get_type_name(), $sformatf("linker failed (%0d): %s", status, cmd))

    cmd = $sformatf("wsl bash /home/shady_wsl/fpga_ws/risc-v/uvm/golden_model/run_spike.sh %0d %s %s",
                     max_instructions, elf_file, trace_file);
    status = $system(cmd);
    if (status != 0)
        `uvm_error(get_type_name(), $sformatf("spike failed (%0d): %s", status, cmd))

    expected_q.delete();
    fd = $fopen(trace_file, "r");

    while ($fgets(line, fd)) begin
        n = $sscanf(line, "core %d: %d 0x%h (0x%h)", core_id, priv, pc, instr);
        if (n != 4) continue; // blank/unrecognized line

        if (pc >= 32'h100) continue; // the x31 setup/jump-back code, not the real program

        exp = instr_result::type_id::create("exp");
        exp.addr = pc >> 2;

        // Most specific shape first: register write + memory read (LW).
        n = $sscanf(line, "core %d: %d 0x%h (0x%h) x%d 0x%h mem 0x%h",
                    core_id, priv, pc, instr, reg_idx, regval, memaddr);
        if (n == 7) begin
            exp.regw = 1;
            exp.rd = reg_idx;
            exp.reg_wdata = regval;
            exp.memw = 0;
        end else begin
            // Memory write (SW): address + data, no register.
            n = $sscanf(line, "core %d: %d 0x%h (0x%h) mem 0x%h 0x%h",
                        core_id, priv, pc, instr, memaddr, memdata);
            if (n == 6) begin
                exp.regw = 0;
                exp.memw = 1;
                exp.mem_addr = memaddr - 32'h80018000;
                exp.mem_wdata = memdata;
            end else begin
                // Register write only.
                n = $sscanf(line, "core %d: %d 0x%h (0x%h) x%d 0x%h",
                            core_id, priv, pc, instr, reg_idx, regval);
                if (n == 6) begin
                    exp.regw = 1;
                    exp.rd = reg_idx;
                    exp.reg_wdata = regval;
                    exp.memw = 0;
                end else begin
                    // No side effect at all (e.g. a branch).
                    exp.regw = 0;
                    exp.memw = 0;
                end
            end
        end

        expected_q.push_back(exp);
    end

    $fclose(fd);

    for (int i = 0; i < expected_q.size(); i++) begin
        `uvm_info(get_type_name(),
            $sformatf("expected_q[%0d]: addr=%0d regw=%0d rd=%0d reg_wdata=0x%0h memw=%0d mem_addr=0x%0h mem_wdata=0x%0h",
                i, expected_q[i].addr, expected_q[i].regw, expected_q[i].rd, expected_q[i].reg_wdata,
                expected_q[i].memw, expected_q[i].mem_addr, expected_q[i].mem_wdata), UVM_LOW)
    end
endtask

function void write_result(instr_result r);
    instr_result exp;

    if (addr_seen[r.addr]) begin
        wrapped = 1;
        return;
    end
    addr_seen[r.addr] = 1;

    `uvm_info(get_type_name(),
        $sformatf("got[%0d]: addr=%0d regw=%0d rd=%0d reg_wdata=0x%0h memw=%0d mem_addr=0x%0h mem_wdata=0x%0h",
            retire_count, r.addr, r.regw, r.rd, r.reg_wdata, r.memw, r.mem_addr, r.mem_wdata), UVM_LOW)
    retire_count++;

    if (expected_q.size() == 0) begin
        `uvm_error(get_type_name(), "no more expected results -- DUT outran Spike's trace")
        return;
    end
    exp = expected_q.pop_front();

    // Signal-level: did the pipeline compute/assert the right thing?
    if (r.regw != exp.regw) begin
        `uvm_error(get_type_name(),
            $sformatf("reg mismatch @addr %0d: got regw=%0d, expected regw=%0d",
                r.addr, r.regw, exp.regw))
    end else if (r.regw && (r.rd != exp.rd || r.reg_wdata != exp.reg_wdata)) begin
        `uvm_error(get_type_name(),
            $sformatf("reg mismatch @addr %0d: got rd=%0d data=0x%0h, expected rd=%0d data=0x%0h",
                r.addr, r.rd, r.reg_wdata, exp.rd, exp.reg_wdata))
    end

    if (r.memw != exp.memw) begin
        `uvm_error(get_type_name(),
            $sformatf("mem mismatch @addr %0d: got memw=%0d, expected memw=%0d",
                r.addr, r.memw, exp.memw))
    end else if (r.memw && (r.mem_addr != exp.mem_addr || r.mem_wdata != exp.mem_wdata)) begin
        `uvm_error(get_type_name(),
            $sformatf("mem mismatch @addr %0d: got addr=0x%0h data=0x%0h, expected addr=0x%0h data=0x%0h",
                r.addr, r.mem_addr, r.mem_wdata, exp.mem_addr, exp.mem_wdata))
    end

    // Storage-level: did the register file / data memory actually hold onto it?
    if (r.regw && exp.regw && tb_top.dut.regfile.registers[r.rd] != exp.reg_wdata) begin
        `uvm_error(get_type_name(),
            $sformatf("regfile[%0d] actually holds 0x%0h, expected 0x%0h",
                r.rd, tb_top.dut.regfile.registers[r.rd], exp.reg_wdata))
        `uvm_info(get_type_name(),
            $sformatf("  regfile write port right now: wenable=%0d waddr=%0d wdata=0x%0h (regw_memwb=%0d valid_memwb=%0d rd_memwb=%0d)",
                tb_top.dut.regfile.wenable, tb_top.dut.regfile.waddr, tb_top.dut.regfile.wdata,
                tb_top.dut.regw_memwb, tb_top.dut.valid_memwb, tb_top.dut.rd_memwb), UVM_LOW)
    end

    if (r.memw && exp.memw && tb_top.dut.dmem.datas[r.mem_addr[7:2]] != exp.mem_wdata) begin
        `uvm_error(get_type_name(),
            $sformatf("dmem[%0d] actually holds 0x%0h, expected 0x%0h",
                r.mem_addr[7:2], tb_top.dut.dmem.datas[r.mem_addr[7:2]], exp.mem_wdata))
    end
endfunction

// 9 legal opcodes + 7 legal funct3 values + 3 x0-corner-case booleans.
function void report_phase(uvm_phase phase);
    int total_bins, covered_bins;
    real pct;

    total_bins = 9 + 7 + 2 + 2 + 2;
    covered_bins = opcode_seen.num() + funct3_seen.num() + rd_x0_seen.num()
                 + rs1_x0_seen.num() + rs2_x0_seen.num();
    pct = 100.0 * covered_bins / total_bins;

    `uvm_info(get_type_name(),
        $sformatf("functional coverage: %0.2f%% (%0d/%0d bins) -- opcode=%0d/9 funct3=%0d/7 rd_x0=%0d/2 rs1_x0=%0d/2 rs2_x0=%0d/2",
            pct, covered_bins, total_bins, opcode_seen.num(), funct3_seen.num(),
            rd_x0_seen.num(), rs1_x0_seen.num(), rs2_x0_seen.num()), UVM_LOW)
endfunction

endclass
