package apb_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    class apb_item extends uvm_sequence_item;
        rand bit write;
        rand bit [7:0] address;
        rand bit [31:0] data;
        bit [31:0] read_data;
        bit error;
        constraint aligned_c { address[1:0] == 0; }
        `uvm_object_utils_begin(apb_item)
            `uvm_field_int(write, UVM_ALL_ON)
            `uvm_field_int(address, UVM_ALL_ON)
            `uvm_field_int(data, UVM_ALL_ON)
        `uvm_object_utils_end
        function new(string name="apb_item"); super.new(name); endfunction
    endclass

    class apb_sequence extends uvm_sequence #(apb_item);
        `uvm_object_utils(apb_sequence)
        function new(string name="apb_sequence"); super.new(name); endfunction
        task body();
            repeat (50) begin
                req = apb_item::type_id::create("req");
                start_item(req);
                assert(req.randomize() with { address < 8'h40; });
                finish_item(req);
            end
        endtask
    endclass

    class apb_driver extends uvm_driver #(apb_item);
        `uvm_component_utils(apb_driver)
        virtual apb_if vif;
        function new(string n, uvm_component p); super.new(n,p); endfunction
        function void build_phase(uvm_phase phase);
            if (!uvm_config_db#(virtual apb_if)::get(this,"","vif",vif))
                `uvm_fatal("NOVIF","APB interface not configured")
        endfunction
        task run_phase(uvm_phase phase);
            forever begin
                seq_item_port.get_next_item(req);
                @(negedge vif.PCLK);
                vif.PSEL=1; vif.PENABLE=0; vif.PWRITE=req.write;
                vif.PADDR=req.address; vif.PWDATA=req.data;
                @(negedge vif.PCLK); vif.PENABLE=1;
                do @(negedge vif.PCLK); while (!vif.PREADY);
                req.read_data=vif.PRDATA; req.error=vif.PSLVERR;
                vif.PSEL=0; vif.PENABLE=0;
                seq_item_port.item_done();
            end
        endtask
    endclass

    class apb_monitor extends uvm_monitor;
        `uvm_component_utils(apb_monitor)
        virtual apb_if vif;
        uvm_analysis_port #(apb_item) ap;
        function new(string n, uvm_component p); super.new(n,p); ap=new("ap",this); endfunction
        function void build_phase(uvm_phase phase);
            if (!uvm_config_db#(virtual apb_if)::get(this,"","vif",vif))
                `uvm_fatal("NOVIF","APB interface not configured")
        endfunction
        task run_phase(uvm_phase phase);
            forever begin
                @(posedge vif.PCLK);
                if (vif.PSEL && vif.PENABLE && vif.PREADY) begin
                    apb_item t=apb_item::type_id::create("t");
                    t.write=vif.PWRITE; t.address=vif.PADDR; t.data=vif.PWDATA;
                    t.read_data=vif.PRDATA; t.error=vif.PSLVERR; ap.write(t);
                end
            end
        endtask
    endclass

    class apb_scoreboard extends uvm_subscriber #(apb_item);
        `uvm_component_utils(apb_scoreboard)
        bit [31:0] model [0:15];
        function new(string n, uvm_component p); super.new(n,p); endfunction
        function void write(apb_item t);
            int index=t.address>>2;
            if (!t.error && t.write) model[index]=t.data;
            else if (!t.error && !t.write && t.read_data!==model[index])
                `uvm_error("DATA",$sformatf("Mismatch at 0x%0h",t.address))
        endfunction
    endclass

    class apb_coverage extends uvm_subscriber #(apb_item);
        `uvm_component_utils(apb_coverage)
        apb_item sample;
        covergroup cg;
            option.per_instance=1;
            rw: coverpoint sample.write;
            addr: coverpoint sample.address { bins valid[]={[0:8'h3c]}; bins invalid=default; }
            err: coverpoint sample.error;
            rw_x_err: cross rw, err;
        endgroup
        function new(string n, uvm_component p); super.new(n,p); cg=new; endfunction
        function void write(apb_item t); sample=t; cg.sample(); endfunction
    endclass

    class apb_agent extends uvm_agent;
        `uvm_component_utils(apb_agent)
        uvm_sequencer #(apb_item) seqr; apb_driver drv; apb_monitor mon;
        function new(string n, uvm_component p); super.new(n,p); endfunction
        function void build_phase(uvm_phase phase);
            seqr=uvm_sequencer#(apb_item)::type_id::create("seqr",this);
            drv=apb_driver::type_id::create("drv",this);
            mon=apb_monitor::type_id::create("mon",this);
        endfunction
        function void connect_phase(uvm_phase phase); drv.seq_item_port.connect(seqr.seq_item_export); endfunction
    endclass

    class apb_env extends uvm_env;
        `uvm_component_utils(apb_env)
        apb_agent agent; apb_scoreboard sb; apb_coverage cov;
        function new(string n, uvm_component p); super.new(n,p); endfunction
        function void build_phase(uvm_phase phase);
            agent=apb_agent::type_id::create("agent",this);
            sb=apb_scoreboard::type_id::create("sb",this);
            cov=apb_coverage::type_id::create("cov",this);
        endfunction
        function void connect_phase(uvm_phase phase);
            agent.mon.ap.connect(sb.analysis_export); agent.mon.ap.connect(cov.analysis_export);
        endfunction
    endclass

    class apb_test extends uvm_test;
        `uvm_component_utils(apb_test)
        apb_env env;
        function new(string n, uvm_component p); super.new(n,p); endfunction
        function void build_phase(uvm_phase phase); env=apb_env::type_id::create("env",this); endfunction
        task run_phase(uvm_phase phase);
            apb_sequence seq=apb_sequence::type_id::create("seq");
            phase.raise_objection(this); seq.start(env.agent.seqr); phase.drop_objection(this);
        endtask
    endclass
endpackage
