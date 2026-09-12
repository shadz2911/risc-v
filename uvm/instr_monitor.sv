import uvm_pkg::*;
`include "uvm_macros.svh"

class instr_monitor extends uvm_monitor;

`uvm_component_utils(instr_monitor)

uvm_analysis_port #(instr_result) ap;

function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
endfunction

task run_phase(uvm_phase phase);

    bit wr_buffer;
    bit [31:0] rdata2_buffer;
    bit [31:0] alu_result_buffer;

    forever begin
        @(posedge tb_top.clk);

        instr_result result;

        if (tb_top.dut.valid_memwb) begin
            result = instr_result::type_id::create("result");
            result.addr = (tb_top.dut.pc_plus4_memwb - 4) >> 2;
            result.regw = tb_top.dut.regw_memwb;
            result.rd = tb_top.dut.rd_memwb;
            result.reg_wdata = tb_top.dut.wdata;
            result.memw = wr_buffer;
            result.mem_addr = alu_result_buffer;
            result.mem_wdata = rdata2_buffer;
            ap.write(result);
        end

        wr_buffer = tb_top.dut.memw_exmem && tb_top.dut.valid_exmem;
        rdata2_buffer = tb_top.dut.rdata2_exmem;
        alu_result_buffer = tb_top.dut.alu_result_exmem;
    end
endtask

endclass
