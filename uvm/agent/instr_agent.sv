import uvm_pkg::*;
`include "uvm_macros.svh"

// creates sequencer and driver objects and connects appropriate ports
class instr_agent extends uvm_agent;

`uvm_component_utils(instr_agent)

instr_sequencer sequencer;
instr_driver driver;
instr_monitor monitor;

function new(string name, uvm_component parent);
    super.new(name, parent);
endfunction

function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sequencer = instr_sequencer::type_id::create("sequencer", this);
    driver = instr_driver::type_id::create("driver", this);
    monitor = instr_monitor::type_id::create("monitor", this);
endfunction

function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    driver.seq_item_port.connect(sequencer.seq_item_export);
endfunction

endclass
