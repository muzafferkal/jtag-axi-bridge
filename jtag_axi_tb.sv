// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

/// Selectively test the JTAG axi.
module jtag_axi_tb;

  logic clk, rst_n;

// Supported Instructions
    localparam BYPASS   = 5'h0;
    localparam IDCODE   = 5'h1;
    localparam DTMCSR   = 5'h10;
    localparam DMIACCESS = 5'h11;
    localparam BYPASS1   = 5'h1f;

  localparam time ClkPeriod = 10ns;
  localparam time ApplTime =  2ns;
  localparam time TestTime =  8ns;

  localparam time JTAGPeriod = time'(50ns);

  localparam int unsigned AW = 18;
  localparam IDCode = 32'hdeadbeef | 32'b1;

  // ----------------
  // Clock generation
  // ----------------
  initial begin
    rst_n = 0;
    repeat (3) begin
      #(ClkPeriod/2) clk = 0;
      #(ClkPeriod/2) clk = 1;
    end
    rst_n = 1;
    forever begin
      #(ClkPeriod/2) clk = 0;
      #(ClkPeriod/2) clk = 1;
    end
  end

  logic tck;

  initial begin
    #100ns;
    forever begin
      tck = 1;
      #(JTAGPeriod/2);
      tck = 0;
      #(JTAGPeriod/2);
    end
  end

    logic dut_tck, dut_tms, dut_trstn, dut_tdi, dut_tdo;
    logic start_rand;

    AXI_LITE #(.AXI_ADDR_WIDTH(18), .AXI_DATA_WIDTH(32)) axilite();
  
    logic testmode_i;
    logic tms;
    logic trst_;
    logic tdi;
    logic td_o;
    logic tdo_oe;
    logic tdo_en;

    wire tdo = tdo_oe ? td_o : 1'bZ;
    pullup rpu(tdo);

    localparam GP_ADDR_WIDTH = 4;
    localparam C_S_AXI_DATA_WIDTH = 32;
    localparam C_S_AXI_ADDR_WIDTH = 17;

    logic write; //New write request
    logic [GP_ADDR_WIDTH-1:0] write_addrs; //Address to write
    logic [C_S_AXI_DATA_WIDTH-1:0] write_data; //Data to write
    logic write_error; //Indicate an error to master
    logic write_done; //Indicate to finish write next cycle (ready signal in AXI)
    logic [(C_S_AXI_DATA_WIDTH/8)-1 : 0] write_strobe;
    //Read Channel
    logic read; //New read request
    logic [GP_ADDR_WIDTH-1:0] read_addrs; //Address to read
    logic [C_S_AXI_DATA_WIDTH-1:0] read_data; //Read data
    logic read_error; //Indicate an error to master
    logic read_done; //Indicate to read_data is valid

    logic [31:0] memory[1024];

    always_latch begin : target_memory
      if (read) read_data = memory[read_addrs];
      if (write) memory[write_addrs] = write_data;
      write_done = 1;
      write_error = 0;
      read_done = 1;
      read_error = 0;
    end

    axi_lite_slave_v1_0 
    #(
      .GP_ADDR_WIDTH      (GP_ADDR_WIDTH     ),
      .C_S_AXI_DATA_WIDTH (C_S_AXI_DATA_WIDTH),
      .C_S_AXI_ADDR_WIDTH (C_S_AXI_ADDR_WIDTH)
    )
    u_axi_lite_slave_v1_0(
      .write         (write         ),
      .write_addrs   (write_addrs   ),
      .write_data    (write_data    ),
      .write_error   (write_error   ),
      .write_done    (write_done    ),
      .write_strobe  (write_strobe  ),
      .read          (read          ),
      .read_addrs    (read_addrs    ),
      .read_data     (read_data     ),
      .read_error    (read_error    ),
      .read_done     (read_done     ),
      .s_axi_aclk    (clk    ),
      .s_axi_aresetn (rst_n ),
      .s_axi_awaddr  (axilite.aw_addr  ),
      .s_axi_awprot  (axilite.aw_prot  ),
      .s_axi_awvalid (axilite.aw_valid ),
      .s_axi_awready (axilite.aw_ready ),
      .s_axi_wdata   (axilite.w_data   ),
      .s_axi_wstrb   (axilite.w_strb   ),
      .s_axi_wvalid  (axilite.w_valid  ),
      .s_axi_wready  (axilite.w_ready  ),
      .s_axi_bresp   (axilite.b_resp   ),
      .s_axi_bvalid  (axilite.b_valid  ),
      .s_axi_bready  (axilite.b_ready  ),
      .s_axi_araddr  (axilite.ar_addr  ),
      .s_axi_arprot  (axilite.ar_prot  ),
      .s_axi_arvalid (axilite.ar_valid ),
      .s_axi_arready (axilite.ar_ready ),
      .s_axi_rdata   (axilite.r_data   ),
      .s_axi_rresp   (axilite.r_resp   ),
      .s_axi_rvalid  (axilite.r_valid  ),
      .s_axi_rready  (axilite.r_ready  )
    );

    jtag_axi 
    #(
    .IdcodeValue (IDCode)
    )
    u_jtag_axi(
    .clk_i      (clk        ),
    .rst_ni     (rst_n      ),
    .testmode_i (testmode_i ),
    .axilite    (axilite    ),
    .tck_i      (tck        ),
    .tms_i      (tms        ),
    .trst_ni    (trst_      ),
    .td_i       (tdi        ),
    .td_o       (td_o       ),
    .tdo_oe_o   (tdo_oe     )
    );

    parameter IR_LENGTH     =  5;
    parameter MAX_TDO_VEC   = 64;
 
//    reg trst_, tck, tdi, tms, tdo_en;

    initial begin
        $display("%t: Start of simulation!", $time);
        $dumpfile("jtag_axi.fst");
        $dumpvars(0, jtag_axi_tb);

        trst_   = 0;
        repeat(10) @(posedge tck);
        trst_   = 1;

        repeat(10000) @(posedge tck);
        $display("%t: Simulation complete...", $time);
        $finish;
    end

    task jtag_clocked_reset;
        begin
            $display("%t: JTAG Clocked Reset", $time);
            tms = 1;
            repeat(5) @(negedge tck);
        end
    endtask

    task jtag_apply_tms;
        input tms_in;
        begin
            //$display("Apply TMS %d", tms_in);
            tms = tms_in;
            @(negedge tck);
        end
    endtask

    task jtag_reset_to_run_test_idle;
        begin
            $display("%t: Reset to Run-Test-Idle", $time);

            // Go to RTI
            tms = 0;
            @(negedge tck);
        end
    endtask

    task jtag_scan_vector;

        input [255:0]   vector_in;
        input integer   nr_bits;
        input           exit1;

        integer i;
        begin
            for(i=0; i<nr_bits; i=i+1) begin
                tdi = vector_in[i];

                if (i == nr_bits-1) begin
                    tms = exit1;            // Go to Exit1-*
                end
                @(negedge tck);
            end
        end
    endtask

    task jtag_scan_ir;
        input [IR_LENGTH-1:0] wanted_ir;

        integer i;
        begin
            $display("%t: Set IR 0x%02x", $time, wanted_ir);

            // Go to Select-DR-Scan
            jtag_apply_tms(1);

            // Go to Select-IR-Scan
            jtag_apply_tms(1);

            // Go to Capture-IR
            jtag_apply_tms(0);

            // Go to Shift-IR
            jtag_apply_tms(0);
            tdo_en = 1;

            // Shift vector, then go to EXIT1_IR
            jtag_scan_vector(wanted_ir, IR_LENGTH, 1);

            // Go to Update-IR
            tdo_en = 0;

            jtag_apply_tms(1);

            // Go to Run Test Idle
            jtag_apply_tms(0);
        end
    endtask

    task jtag_scan_dr;
        input [255:0]   vector_in;
        input integer   nr_bits;
        input           early_out;

        integer i;
        begin
            $display("%t: Set DR to 0x%x", $time, vector_in);

            // Go to Select-DR-Scan
            jtag_apply_tms(1);

            // CAPTURE_DR
            jtag_apply_tms(0);
    
            // SHIFT_DR
            jtag_apply_tms(0);
            tdo_en = 1;
    
            // Shift vector, then go to EXIT1_DR
            jtag_scan_vector(vector_in, nr_bits, 1);

            tdo_en = 0;

            if (early_out) begin
                // EXIT1_DR -> UPDATE_DR
                jtag_apply_tms(1);
            end
            else begin
                // EXIT1_DR -> PAUSE_DR
                jtag_apply_tms(0);

                // PAUSE_DR -> EXIT2_DR
                jtag_apply_tms(1);

                // EXIT2_DR -> UPDATE_DR
                jtag_apply_tms(1);
            end
    
            // UPDATE_DR -> RUN_TEST_IDLE
            jtag_apply_tms(0);
        end
    endtask

    reg [MAX_TDO_VEC-1:0]   captured_tdo_vec;
    initial begin: CAPTURE_TDO
        integer                 bit_cntr;

        forever begin
            while(!tdo_en) begin
                @(posedge tck);
            end
            bit_cntr = 0;
            //captured_tdo_vec = {MAX_TDO_VEC{1'bz}};
            while(tdo_en) begin
                captured_tdo_vec[bit_cntr] = tdo;
                bit_cntr = bit_cntr + 1;
                //$display("tdo: %d bit_cntr %d cap %X", tdo, bit_cntr, captured_tdo_vec);
                @(posedge tck);
            end
            $display("%t: TDO_CAPTURED: %b", $time, captured_tdo_vec);
            @(posedge tck);
            captured_tdo_vec = 0;
        end
    end

    initial begin
        tdi = 0;
        tms = 0;
        tdo_en = 0;

        @(posedge trst_);
        @(negedge tck);

        jtag_clocked_reset();

        jtag_reset_to_run_test_idle();

        //============================================================
        // Default IR should be IDCODE. Shift it out...
        //============================================================
        
        // SELECT_DR_SCAN
        jtag_apply_tms(1);
        
        // CAPTURE_DR
        jtag_apply_tms(0);

        // SHIFT_DR
        jtag_apply_tms(0);

        // Scan out IDCODE
        tdo_en = 1;
        jtag_scan_vector(32'h0, 32, 1);

        // EXIT1_DR -> UPDATE_DR
        tdo_en = 0;
        jtag_apply_tms(1);

        // UPDATE_DR -> RUN_TEST_IDLE
        jtag_apply_tms(0);

        $display("%t: IDCODE scanned out: %x", $time, captured_tdo_vec[31:0]);

        //============================================================
        // Select IR 0xa
        //============================================================
        jtag_scan_ir(BYPASS);
//        jtag_scan_ir(4'ha);

        //============================================================
        // Select IDCODE register
        //============================================================
        jtag_scan_ir(IDCODE);
        jtag_scan_dr(32'h00000DB3, 32, 1);

        //============================================================
        // GPIOs
        //============================================================

        // 
        $display("access DMIACCESS");
        $display("read address 3");
        jtag_scan_ir(DMIACCESS);
        jtag_scan_dr({17'h3, 32'hfaceb00c, 2'h1}, 51, 0);
        $display("write to address 3");
        jtag_scan_ir(DMIACCESS);
        jtag_scan_dr({17'h3, 32'hfaceb00c, 2'h2}, 51, 0);
        $display("read address 3");
        jtag_scan_ir(DMIACCESS);
        jtag_scan_dr({17'h3, 32'hfaceb00c, 2'h1}, 51, 0);

        // $display("CONFIG - EXTEST WR");
        // jtag_scan_ir(`EXTEST);
        // jtag_scan_dr(4'b1111, 4, 0);

        // // capture_dr without update_dr (to read back the value)
        // $display("CONFIG - EXTEST RD");
        // jtag_scan_dr(4'b0000, 4, 0);

        // // Set GPIO output values
        // $display("DATA - SCAN_N");
        // jtag_scan_ir(`SCAN_N);
        // jtag_scan_dr(1'b1, 1, 0);
        // $display("DATA - EXTEST");
        // jtag_scan_ir(`EXTEST);

        // jtag_scan_dr(4'b1111, 4, 1);
        // jtag_scan_dr(4'b1000, 4, 0);
        // jtag_scan_dr(4'b1001, 4, 1);
        // jtag_scan_dr(4'b1010, 4, 0);
        // jtag_scan_dr(4'b1011, 4, 0);
        // jtag_scan_dr(4'b1100, 4, 0);
        // jtag_scan_dr(4'b1101, 4, 0);
        // jtag_scan_dr(4'b1110, 4, 0);
        // jtag_scan_dr(4'b1111, 4, 0);
        // jtag_scan_dr(4'b1000, 4, 0);

    end

endmodule
