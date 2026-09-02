.PHONY: test uvm wave clean
test:
	bash scripts/run_smoke.sh
uvm:
	bash scripts/run_questa.sh
wave:
	gtkwave proof/apb_wave.vcd
clean:
	rm -rf sim_build work transcript vsim.wlf
