module if_id_reg (
    input logic clk,
    input logic reset,
    input logic stall,
    input logic flush,

    input logic [31:0] instr_in,
    input logic [31:0] pc_plus4_in,
    input logic [31:0] current_pc_in,
    input logic predict_taken_in,
    input logic hit_in,
    input logic [31:0] target_in,

    output logic [31:0] instr_out,
    output logic [31:0] pc_plus4_out,
    output logic [31:0] current_pc_out,
    output logic valid_out,
    output logic predict_taken_out,
    output logic hit_out,
    output logic [31:0] target_out
);

always_ff @(posedge clk) begin
    if (reset) begin
        instr_out <= 0;
        pc_plus4_out <= 0;
        current_pc_out <= 0;
        valid_out <= 0;
        predict_taken_out <= 0;
        hit_out <= 0;
        target_out <= 0;
    end
    else begin
        if (flush) begin
            valid_out <= 0;
        end
        else if (!stall) begin
            valid_out <= 1;
        end

        if (!stall) begin
            instr_out <= instr_in;
            pc_plus4_out <= pc_plus4_in;
            current_pc_out <= current_pc_in;
            predict_taken_out <= predict_taken_in;
            hit_out <= hit_in;
            target_out <= target_in;
        end
    end
end

endmodule
