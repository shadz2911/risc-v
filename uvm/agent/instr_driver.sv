import uvm_pkg::*;
`include "uvm_macros.svh"

// Consumes instr_transactions from the sequencer
// Puts said instruction into DUT
class instr_driver extends uvm_driver #(instr_transaction);

`uvm_component_utils(instr_driver)

uvm_analysis_port #(instr_transaction) ap;

function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
endfunction

task run_phase(uvm_phase phase);
    forever begin
        seq_item_port.get_next_item(req);
        tb_top.dut.imem.instructions[req.addr] = req.encode();
        ap.write(req);
        seq_item_port.item_done();
    end
endtask

endclass
