module jtag_axi_tb;


AXI_LITE #(.AXI_ADDR_WIDTH(17), .AXI_DATA_WIDTH(32)) axilite();

logic         clk_i;      // AXI Clock
logic         rst_ni;     // Asynchronous reset active low
logic         testmode_i;
logic         tck_i;    // JTAG test clock pad
logic         tms_i;    // JTAG test mode select pad
logic         trst_ni;  // JTAG test reset pad
logic         td_i;     // JTAG test data input pad
logic         td_o;     // JTAG test data output pad
logic         tdo_oe_o;  // Data out output enable

jtag_axi u_jtag_axi(
    .clk_i      (clk_i      ),
    .rst_ni     (rst_ni     ),
    .testmode_i (testmode_i ),
    .axilite    (axilite    ),
    .tck_i      (tck_i      ),
    .tms_i      (tms_i      ),
    .trst_ni    (trst_ni    ),
    .td_i       (td_i       ),
    .td_o       (td_o       ),
    .tdo_oe_o   (tdo_oe_o   )
);

endmodule