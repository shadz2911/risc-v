import uvm_pkg::*;
`include "uvm_macros.svh"

class instr_test extends uvm_test;

`uvm_component_utils(instr_test)

instr_env env;

function new(string name = "instr_test", uvm_component parent = null);
    super.new(name, parent);
endfunction

function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = instr_env::type_id::create("env", this);
endfunction

task run_phase(uvm_phase phase);
    instr_sequence seq;

    phase.raise_objection(this);

    tb_top.reset = 1;
    repeat (2) @(posedge tb_top.clk);
    for (int i = 0; i < 32; i++) tb_top.dut.regfile.registers[i] = 0;
    for (int i = 0; i < 64; i++) tb_top.dut.dmem.datas[i] = 0;

    seq = instr_sequence::type_id::create("seq");
    seq.start(env.agent.sequencer);

    tb_top.reset = 0;
    repeat (500) @(posedge tb_top.clk);
    #1;

    phase.drop_objection(this);
endtask

endclass
