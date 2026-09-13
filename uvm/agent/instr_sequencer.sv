import uvm_pkg::*;
`include "uvm_macros.svh"

class instr_sequencer extends uvm_sequencer #(instr_transaction);

`uvm_component_utils(instr_sequencer)

function new(string name, uvm_component parent);
    super.new(name, parent);
endfunction

endclass
