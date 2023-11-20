module dmi_axi #(
  parameter logic [31:0] IdcodeValue = 32'h00000DB3
) (
    input  logic            clk_i,      // AXI Clock
    input  logic            rst_ni,     // Asynchronous reset active low

    AXI_LITE.Initiator      axilite,

    input logic             dmi_rst_n_i,
    input dm::dmi_req_t     dmi_req_i,
    input logic             dmi_req_valid_i,
    output  logic           dmi_req_ready_o,
    output dm::dmi_resp_t   dmi_resp_o,
    input logic             dmi_resp_ready_i,
    output  logic           dmi_resp_valid_o
);

    always_comb begin : blockName
        axilite.aw_addr  = dmi_req_i.op == dm::DTM_WRITE ? dmi_req_i.addr : 0;
        axilite.aw_valid = dmi_req_i.op == dm::DTM_WRITE ? dmi_req_valid_i : 0;
        axilite.aw_prot  = 3'h0;

        axilite.w_valid  = dmi_req_i.op == dm::DTM_WRITE ? dmi_req_valid_i : 0;
        axilite.w_data   = dmi_req_i.op == dm::DTM_WRITE ? dmi_req_i.data : 0;
        axilite.w_strb   = 4'hF;

        // TODO(kal) this is broken
        dmi_req_ready_o = axilite.aw_ready && axilite.w_ready || axilite.ar_ready;

        axilite.ar_addr  = dmi_req_i.op == dm::DTM_READ ? dmi_req_i.addr : 0;
        axilite.ar_valid = dmi_req_i.op == dm::DTM_READ ? dmi_req_valid_i : 0;
        axilite.ar_prot  = 3'h0;

        dmi_resp_o.data = dmi_req_i.op == dm::DTM_READ ? axilite.r_data : 32'h0;
        dmi_resp_o.resp = dmi_req_i.op == dm::DTM_READ ? axilite.r_resp : 2'b0;

        // TODO(kal) check if it's ok not to manage B channel
        dmi_resp_valid_o = axilite.r_valid;
        axilite.r_ready  = dmi_resp_ready_i;
    end

endmodule