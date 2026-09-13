import uvm_pkg::*;
`include "uvm_macros.svh"

class instr_result extends uvm_sequence_item;

`uvm_object_utils(instr_result)

bit [5:0] addr;

bit regw;
bit [4:0] rd;
bit [31:0] reg_wdata;

bit memw;
bit [31:0] mem_addr;
bit [31:0] mem_wdata;

function new(string name = "instr_result");
    super.new(name);
endfunction

endclass
