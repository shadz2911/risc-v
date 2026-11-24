
module forward_sel_formal (
    input logic       clk,
    input logic       rst,
    input logic       regw_exmem,
    input logic       regw_memwb,
    input logic [4:0] rd_exmem,
    input logic [4:0] rd_memwb,
    input logic [4:0] rs1_idex,
    input logic [4:0] rs2_idex,
    input control_pkg::regpc_t     regpc_idex,
    input control_pkg::alusrc_t    alusrc_idex
);

control_pkg::fw_t fw_a, fw_b, fw_r2;

forward_sel dut (
    .regw_exmem (regw_exmem),
    .regw_memwb (regw_memwb),
    .rd_exmem   (rd_exmem),
    .rd_memwb   (rd_memwb),
    .rs1_idex   (rs1_idex),
    .rs2_idex   (rs2_idex),
    .regpc_idex (regpc_idex),
    .alusrc_idex(alusrc_idex),
    .fw_a       (fw_a),
    .fw_b       (fw_b),
    .fw_r2      (fw_r2)
);

reg init = 1;
always @(posedge clk) init <= 0;

always @(*) begin
    if (init) assume(rst);
end

// helper wires
wire rs1_write_exmem = regw_exmem && (rd_exmem != 0) && (rd_exmem == rs1_idex) && (regpc_idex == control_pkg::use_rs1);
wire rs1_write_memwb = regw_memwb && (rd_memwb != 0) && (rd_memwb == rs1_idex) && (regpc_idex == control_pkg::use_rs1);
wire rs2_write_exmem = regw_exmem && (rd_exmem != 0) && (rd_exmem == rs2_idex) && (alusrc_idex == control_pkg::use_reg);
wire rs2_write_memwb = regw_memwb && (rd_memwb != 0) && (rd_memwb == rs2_idex) && (alusrc_idex == control_pkg::use_reg);
wire rdata2_write_exmem = regw_exmem &&(rd_exmem != 0) && (rd_exmem == rs2_idex);
wire rdata2_write_memwb = regw_memwb && (rd_memwb != 0) && (rd_memwb == rs2_idex);

always @(*) begin
    if (!init && !rst) begin
        // fw_a properties
        assert(fw_a != 2'b11);
        assert((fw_a == control_pkg::fw_exmem) || !rs1_write_exmem);
        assert((fw_a == control_pkg::fw_memwb) || rs1_write_exmem || !rs1_write_memwb);
        assert((fw_a == control_pkg::fw_none)  || rs1_write_exmem || rs1_write_memwb);

        // fw_b properties
        assert(fw_b != 2'b11);
        assert((fw_b == control_pkg::fw_exmem) || !rs2_write_exmem);
        assert((fw_b == control_pkg::fw_memwb) || rs2_write_exmem || !rs2_write_memwb);
        assert((fw_b == control_pkg::fw_none)  || rs2_write_exmem || rs2_write_memwb);

        // fw_r2 properties
        assert(fw_r2 != 2'b11);
        assert((fw_r2 == control_pkg::fw_exmem) || !rdata2_write_exmem);
        assert((fw_r2 == control_pkg::fw_memwb) || rdata2_write_exmem || !rdata2_write_memwb);
        assert((fw_r2 == control_pkg::fw_none)  || rdata2_write_exmem || rdata2_write_memwb);


        // x0 / encoding properties
        if (rs1_idex == 0) assert(fw_a  == control_pkg::fw_none);
        if (rs2_idex == 0) assert(fw_b  == control_pkg::fw_none);
        if (rs2_idex == 0) assert(fw_r2 == control_pkg::fw_none);

        if (rd_exmem == 0) assert(fw_a  != control_pkg::fw_exmem);
        if (rd_exmem == 0) assert(fw_b  != control_pkg::fw_exmem);
        if (rd_exmem == 0) assert(fw_r2 != control_pkg::fw_exmem);

        if (rd_memwb == 0) assert(fw_a  != control_pkg::fw_memwb);
        if (rd_memwb == 0) assert(fw_b  != control_pkg::fw_memwb);
        if (rd_memwb == 0) assert(fw_r2 != control_pkg::fw_memwb);
    end
end

always @(*) begin
    if (!init && !rst) begin
        cover(fw_a == control_pkg::fw_none);
        cover(fw_a == control_pkg::fw_exmem);
        cover(fw_a == control_pkg::fw_memwb);

        cover(fw_b == control_pkg::fw_none);
        cover(fw_b == control_pkg::fw_exmem);
        cover(fw_b == control_pkg::fw_memwb);

        cover(fw_r2 == control_pkg::fw_none);
        cover(fw_r2 == control_pkg::fw_exmem);
        cover(fw_r2 == control_pkg::fw_memwb);

        cover(rs1_write_exmem && rs1_write_memwb);
    end
end

endmodule
