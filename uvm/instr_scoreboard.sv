import uvm_pkg::*;
`include "uvm_macros.svh"

`uvm_analysis_imp_decl(_prog)
`uvm_analysis_imp_decl(_result)

class instr_scoreboard extends uvm_scoreboard;

`uvm_component_utils(instr_scoreboard)

uvm_analysis_imp_prog #(instr_transaction, instr_scoreboard) prog_export;
uvm_analysis_imp_result #(instr_result, instr_scoreboard) result_export;

instr_transaction loaded_program [64];
bit [31:0] shadow_regs [32];
bit [31:0] shadow_mem [64];

function new(string name, uvm_component parent);
    super.new(name, parent);
    prog_export = new("prog_export", this);
    result_export = new("result_export", this);
endfunction

function void write_prog(instr_transaction t);
    loaded_program[t.addr] = t;
endfunction

function void write_result(instr_result r);
continue
endfunction

endclass
