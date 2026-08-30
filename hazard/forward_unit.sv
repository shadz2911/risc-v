import control_pkg::*;

module forward_sel (
    input logic regw_exmem,
    input logic regw_memwb,
    input logic [4:0] rd_exmem,
    input logic [4:0] rd_memwb,
    input logic [4:0] rs1_idex,
    input logic [4:0] rs2_idex,
    input regpc_t regpc_idex,
    input alusrc_t alusrc_idex,
    output fw_t fw_a,
    output fw_t fw_b,
    output fw_t fw_r2
);

always_comb begin
    // alu-a decision logic
    if (rd_exmem != 0 && regw_exmem && rd_exmem == rs1_idex && regpc_idex == use_rs1) begin
        fw_a = fw_exmem;
    end
    else if (rd_memwb != 0 && regw_memwb && rd_memwb == rs1_idex && regpc_idex == use_rs1) begin
        fw_a = fw_memwb;
    end
    else begin
        fw_a = fw_none;
    end

    // alu-b decision logic
    if (rd_exmem != 0 && regw_exmem && rd_exmem == rs2_idex && alusrc_idex == use_reg) begin
        fw_b = fw_exmem;
    end
    else if (rd_memwb != 0 && regw_memwb && rd_memwb == rs2_idex && alusrc_idex == use_reg) begin
        fw_b = fw_memwb;
    end
    else begin
        fw_b = fw_none;
    end

    // rdata2 decision logic
    if (rd_exmem != 0 && regw_exmem && rd_exmem == rs2_idex) begin
        fw_r2 = fw_exmem;
    end
    else if (rd_memwb != 0 && regw_memwb && rd_memwb == rs2_idex) begin
        fw_r2 = fw_memwb;
    end
    else begin
        fw_r2 = fw_none;
    end
end 

endmodule

module forward_mux (
    input fw_t fw_a,
    input fw_t fw_b,
    input fw_t fw_r2,
    input logic [31:0] alu_a_raw,
    input logic [31:0] alu_b_raw,
    input logic [31:0] rdata2_idex,
    input logic [31:0] alu_result_exmem,
    input logic [31:0] wdata,
    output logic [31:0] alu_a,
    output logic [31:0] alu_b,
    output logic [31:0] r2
);

always_comb begin
    case (fw_a)
        fw_exmem: begin
            alu_a = alu_result_exmem;
        end
        fw_memwb: begin
            alu_a = wdata;
        end
        default: begin
            alu_a = alu_a_raw;
        end
    endcase

    case (fw_b)
        fw_exmem: begin
            alu_b = alu_result_exmem;
        end
        fw_memwb: begin
            alu_b = wdata;
        end
        default: begin
            alu_b = alu_b_raw;
        end
    endcase

    case (fw_r2)
        fw_exmem: begin
            r2 = alu_result_exmem;
        end
        fw_memwb: begin
            r2 = wdata;
        end
        default: begin
            r2 = rdata2_idex;
        end
    endcase
end

endmodule