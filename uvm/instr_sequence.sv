import uvm_pkg::*;
`include "uvm_macros.svh"

// Builds one full 64-word program

class instr_sequence extends uvm_sequence #(instr_transaction);

`uvm_object_utils(instr_sequence)

function new(string name = "instr_sequence");
    super.new(name);
endfunction

task body();
    instr_transaction txn;
    for (int i = 0; i < 64; i++) begin
        txn = instr_transaction::type_id::create($sformatf("txn_%0d", i));
        start_item(txn);

        if (!txn.randomize() with {addr == i;}) begin
            `uvm_error(get_type_name(), $sformatf("randomize failed for addr %0d", i))
        end

        finish_item(txn);
    end
endtask

endclass
