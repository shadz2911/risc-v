module data(
    input logic clk,
    input logic reset,
    input logic [31:0] addr,
    input logic [31:0] wdata,
    input logic wenable,
    output logic [31:0] rdata
);

logic [31:0] datas [0:63];
logic [5:0] word_index;
assign word_index = addr[7:2];

always_ff @(posedge clk) begin
    if (reset) begin
        for (int i = 0; i < 64; i = i + 1) begin
            datas[i] <= 0;
        end
    end else if (wenable) begin
        datas[word_index] <= wdata;
    end
end

always_comb begin
    rdata = datas[word_index];
end
    
endmodule