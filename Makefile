OPT = -O3

VLOG=verilator -sv $(OPT) +incdir+include

#$(VLOG) -cc --timing --exe --timescale 1ns/100ps icg.sv cim.sv cim_tb.sv

jtag_axi: jtag_axi.vlt axi_pkg.sv dm_pkg.sv jtag_intf.sv axi_intf.sv cdc_reset_ctrlr_pkg.sv \
			tc_clk.sv sync.sv cdc_4phase.sv cdc_2phase_clearable.sv axi_intf.sv dmi_intf.sv dm_pkg.sv dmi_jtag.sv \
			dmi_jtag_tap.sv jtag_axi.sv jtag_axi_tb.sv
	@echo $@_tb
	$(VLOG) --cc --timing --binary -Wno-INITIALDLY  --trace-fst --trace-depth 0 --top $@_tb --timescale 1ns/100ps $^

wave:
	gtkwave --save=$(TB).sav $(TB).fst --rcvar 'fontname_signals Monospace 14' --rcvar 'fontname_waves Monospace 14'  --rcvar 'fontname_logfile Monospace 14'

run:
	obj_dir/V$(TB)_tb

clean:
	rm -fR obj_dir
