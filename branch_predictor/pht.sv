module pht (
    input logic clk,
    input logic reset,
    input logic [4:0] pc_read,
    input logic [4:0] pc_write,
    input logic wr_en,
    input logic true_taken,

    output logic predict_taken
);

logic [1:0] prediction_table [0:31];
assign predict_taken = prediction_table[pc_read][1];

always_ff @(posedge clk) begin
    if (reset) begin
        for (int i = 0; i < 32; i++) begin
            prediction_table[i] <= 2'b00;
        end
    end else if (wr_en) begin
        prediction_table[pc_write] <= true_taken ? (prediction_table[pc_write] == 2'b11 ? prediction_table[pc_write] : prediction_table[pc_write] + 1)
        : (prediction_table[pc_write] == 2'b00 ? prediction_table[pc_write] : prediction_table[pc_write] - 1);
    end
end

endmodule