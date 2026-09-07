.PHONY:test wave clean
test:
	bash scripts/run_smoke.sh
wave:test
	gtkwave proof/apb_wave.vcd
clean:
	rm -rf sim_build proof/apb_wave.vcd proof/apb_test.log
