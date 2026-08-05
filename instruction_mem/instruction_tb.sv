module instruction_tb;
    logic [31:0] raddr;
    logic [31:0] instr;

    instruction dut (
        .raddr(raddr),
        .instr(instr)
    );

    initial begin
        $readmemh("program.hex", dut.instructions);

        raddr = 8;
        #1;
        $display("Read address 1: expected 12345678 got=%0h", instr);

        raddr = 0;
        #1;
        $display("Read address 0: expected DEADBEEF got=%0h", instr);

        raddr = 12;
        #1;
        $display("Read address 3: expected FFFFFFFF got=%0h", instr);

        raddr = 20;
        #1;
        $display("blib blob got=%0h", instr);
    end

endmodule