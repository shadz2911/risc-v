import uvm_pkg::*;
`include "uvm_macros.svh"

class instr_env extends uvm_env;

`uvm_component_utils(instr_env)

instr_agent agent;

function new(string name, uvm_component parent);
    super.new(name, parent);
endfunction

function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = instr_agent::type_id::create("agent", this);
endfunction

endclass
