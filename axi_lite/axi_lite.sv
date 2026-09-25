module axi_lite_master #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
)(
    input logic clk,
    input logic rst,

    // cpu-side write request interface
    input logic cpu_wr_req_valid,
    input logic [ADDR_WIDTH-1:0] cpu_wr_req_addr,
    input logic [DATA_WIDTH-1:0] cpu_wr_req_wdata,
    output logic cpu_wr_req_ready,

    output logic cpu_wr_resp_valid,
    output logic cpu_wr_resp_error,

    // cpu-side read request interface
    input logic cpu_rd_req_valid,
    input logic [ADDR_WIDTH-1:0] cpu_rd_req_addr,
    output logic cpu_rd_req_ready,

    output logic cpu_rd_resp_valid,
    output logic [DATA_WIDTH-1:0] cpu_rd_resp_rdata,
    output logic cpu_rd_resp_error,

    // write address channel
    output logic [ADDR_WIDTH-1:0] m_axi_awaddr,
    output logic [2:0] m_axi_awprot,
    output logic m_axi_awvalid,
    input logic m_axi_awready,

    // write data channel
    output logic [DATA_WIDTH-1:0] m_axi_wdata,
    output logic m_axi_wvalid,
    input logic m_axi_wready,

    // write response channel
    input logic [1:0] m_axi_bresp,
    input logic m_axi_bvalid,
    output logic m_axi_bready,

    // read address channel
    output logic [ADDR_WIDTH-1:0] m_axi_araddr,
    output logic [2:0] m_axi_arprot,
    output logic m_axi_arvalid,
    input logic m_axi_arready,

    // read data channel
    input logic [DATA_WIDTH-1:0] m_axi_rdata,
    input logic [1:0] m_axi_rresp,
    input logic m_axi_rvalid,
    output logic m_axi_rready
);

// WRITE related variables
logic aw_complete, w_complete;
assign m_axi_awprot = 3'b000;

logic write_busy, read_busy;
assign write_busy = m_axi_awvalid || m_axi_wvalid || aw_complete || w_complete;
assign read_busy  = m_axi_arvalid || ar_complete;

// WRITE channels block
always_ff @(posedge clk) begin
    // active high synchronous reset like the rest of the CPU
    if (rst) begin
        m_axi_awvalid <= 1'b0;
        m_axi_wvalid <= 1'b0;
        m_axi_bready <= 1'b0;
        aw_complete <= 1'b0;
        w_complete <= 1'b0;
    end else begin
        // AW assignments
        m_axi_awvalid <= m_axi_awvalid && m_axi_awready ? 1'b0 :
            m_axi_awvalid ? m_axi_awvalid :
            cpu_wr_req_valid && !aw_complete ? 1'b1 : 1'b0;

        m_axi_awaddr <= cpu_wr_req_valid && !aw_complete && !m_axi_awvalid ? cpu_wr_req_addr : m_axi_awaddr;
        
        aw_complete <= m_axi_bready && m_axi_bvalid ? 1'b0 :
            aw_complete ? 1'b1 : m_axi_awvalid && m_axi_awready;

        // W assignments
        m_axi_wvalid <= m_axi_wvalid && m_axi_wready ? 1'b0 :
            m_axi_wvalid && !w_complete ? m_axi_wvalid :
            cpu_wr_req_valid && !w_complete ? 1'b1 : 1'b0;

        m_axi_wdata <= cpu_wr_req_valid && !w_complete && !m_axi_wvalid ? cpu_wr_req_wdata : m_axi_wdata;
        
        w_complete <= m_axi_bready && m_axi_bvalid ? 1'b0 :
            w_complete ? 1'b1 : m_axi_wvalid && m_axi_wready;

        // B assignments
        m_axi_bready <= m_axi_bready && m_axi_bvalid ? 1'b0 : 
            m_axi_bready ? m_axi_bready : w_complete && aw_complete;
    end
end

// READ related variables
assign m_axi_arprot = 3'b000;
logic ar_complete;

always_ff @(posedge clk) begin
    if (rst) begin
        m_axi_arvalid <= 1'b0;
        m_axi_rready <= 1'b0;
        ar_complete <= 1'b0;
    end else begin
        // AR assignments
        m_axi_arvalid <= m_axi_arvalid && m_axi_arready ? 1'b0 :
            m_axi_arvalid ? m_axi_arvalid :
            cpu_rd_req_valid && !ar_complete ? 1'b1 : 1'b0;

        m_axi_araddr <= cpu_rd_req_valid && !m_axi_arvalid && !ar_complete ? cpu_rd_req_addr : m_axi_araddr;
        
        ar_complete <= m_axi_rready && m_axi_rvalid ? 1'b0 :
            ar_complete ? 1'b1 : m_axi_arvalid && m_axi_arready;

        // R assignments
        m_axi_rready <= m_axi_rready && m_axi_rvalid ? 1'b0 :
            m_axi_rready ? m_axi_rready : m_axi_arvalid && m_axi_arready;
    end
end

// CPU related assignments

assign cpu_wr_req_ready = !write_busy;
assign cpu_wr_resp_valid = m_axi_bready && m_axi_bvalid;
assign cpu_wr_resp_error = m_axi_bready && m_axi_bvalid && m_axi_bresp[1];

assign cpu_rd_req_ready = !read_busy;
assign cpu_rd_resp_valid = m_axi_rready && m_axi_rvalid;
assign cpu_rd_resp_rdata = m_axi_rdata;
assign cpu_rd_resp_error = m_axi_rready && m_axi_rvalid && m_axi_rresp[1];

endmodule