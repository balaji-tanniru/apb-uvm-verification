package apb_pkg;
  import uvm_pkg::*; `include "uvm_macros.svh"
  class apb_item extends uvm_sequence_item;
    rand bit write; rand bit [7:0] addr; rand bit [31:0] data; bit [31:0] rdata; bit error;
    constraint aligned_valid { addr[1:0]==0; addr inside {[0:8'h3c]}; }
    `uvm_object_utils_begin(apb_item)
      `uvm_field_int(write,UVM_DEFAULT) `uvm_field_int(addr,UVM_HEX) `uvm_field_int(data,UVM_HEX)
      `uvm_field_int(rdata,UVM_HEX) `uvm_field_int(error,UVM_DEFAULT)
    `uvm_object_utils_end
    function new(string name="apb_item"); super.new(name); endfunction
  endclass
  class apb_sequence extends uvm_sequence #(apb_item);
    `uvm_object_utils(apb_sequence)
    function new(string name="apb_sequence"); super.new(name); endfunction
    task body();
      repeat(60) begin
        req=apb_item::type_id::create("req"); start_item(req);
        assert(req.randomize() with { write dist {1:=1,0:=1}; }); finish_item(req);
      end
    endtask
  endclass
  class apb_driver extends uvm_driver #(apb_item);
    `uvm_component_utils(apb_driver) virtual apb_if vif;
    function new(string name,uvm_component parent);super.new(name,parent);endfunction
    function void build_phase(uvm_phase phase);if(!uvm_config_db#(virtual apb_if)::get(this,"","vif",vif))`uvm_fatal("NOVIF","apb_if missing")endfunction
    task run_phase(uvm_phase phase);
      forever begin
        seq_item_port.get_next_item(req);
        @(negedge vif.PCLK); vif.PSEL<=1;vif.PENABLE<=0;vif.PWRITE<=req.write;vif.PADDR<=req.addr;vif.PWDATA<=req.data;
        @(negedge vif.PCLK);vif.PENABLE<=1;
        do @(posedge vif.PCLK); while(!vif.PREADY);
        req.rdata=vif.PRDATA;req.error=vif.PSLVERR;
        @(negedge vif.PCLK);vif.PSEL<=0;vif.PENABLE<=0;
        seq_item_port.item_done();
      end
    endtask
  endclass
  class apb_monitor extends uvm_monitor;
    `uvm_component_utils(apb_monitor) virtual apb_if vif;uvm_analysis_port#(apb_item)ap;
    function new(string name,uvm_component parent);super.new(name,parent);ap=new("ap",this);endfunction
    function void build_phase(uvm_phase phase);if(!uvm_config_db#(virtual apb_if)::get(this,"","vif",vif))`uvm_fatal("NOVIF","apb_if missing")endfunction
    task run_phase(uvm_phase phase);forever begin @(posedge vif.PCLK);if(vif.PRESETn&&vif.PSEL&&vif.PENABLE&&vif.PREADY)begin
      apb_item t=apb_item::type_id::create("t");t.write=vif.PWRITE;t.addr=vif.PADDR;t.data=vif.PWDATA;t.rdata=vif.PRDATA;t.error=vif.PSLVERR;ap.write(t);end end endtask
  endclass
  class apb_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(apb_scoreboard) uvm_analysis_imp#(apb_item,apb_scoreboard)imp;bit[31:0]model[16];int checks,errors;
    function new(string name,uvm_component parent);super.new(name,parent);imp=new("imp",this);foreach(model[i])model[i]='0;endfunction
    function void write(apb_item t);
      if(t.error)return;
      if(t.write)model[t.addr>>2]=t.data;
      else begin checks++;if(t.rdata!==model[t.addr>>2])begin errors++;`uvm_error("APB_DATA",$sformatf("addr=%0h exp=%0h got=%0h",t.addr,model[t.addr>>2],t.rdata))end end
    endfunction
    function void report_phase(uvm_phase phase);`uvm_info("APB_SUMMARY",$sformatf("reads_checked=%0d errors=%0d",checks,errors),UVM_NONE)endfunction
  endclass
  class apb_coverage extends uvm_subscriber#(apb_item);
    `uvm_component_utils(apb_coverage) apb_item tr;
    covergroup cg;cp_dir:coverpoint tr.write;cp_addr:coverpoint tr.addr{bins low={[0:8'h0c]};bins mid={[8'h10:8'h2c]};bins high={[8'h30:8'h3c]};}cp_err:coverpoint tr.error;dir_x_addr:cross cp_dir,cp_addr;endgroup
    function new(string name,uvm_component parent);super.new(name,parent);cg=new;endfunction
    function void write(apb_item t);tr=t;cg.sample();endfunction
  endclass
  class apb_env extends uvm_env;
    `uvm_component_utils(apb_env) uvm_sequencer#(apb_item)seqr;apb_driver drv;apb_monitor mon;apb_scoreboard sb;apb_coverage cov;
    function new(string name,uvm_component parent);super.new(name,parent);endfunction
    function void build_phase(uvm_phase phase);seqr=uvm_sequencer#(apb_item)::type_id::create("seqr",this);drv=apb_driver::type_id::create("drv",this);mon=apb_monitor::type_id::create("mon",this);sb=apb_scoreboard::type_id::create("sb",this);cov=apb_coverage::type_id::create("cov",this);endfunction
    function void connect_phase(uvm_phase phase);drv.seq_item_port.connect(seqr.seq_item_export);mon.ap.connect(sb.imp);mon.ap.connect(cov.analysis_export);endfunction
  endclass
  class apb_test extends uvm_test;
    `uvm_component_utils(apb_test) apb_env env;
    function new(string name,uvm_component parent);super.new(name,parent);endfunction
    function void build_phase(uvm_phase phase);env=apb_env::type_id::create("env",this);endfunction
    task run_phase(uvm_phase phase);apb_sequence seq=apb_sequence::type_id::create("seq");phase.raise_objection(this);seq.start(env.seqr);#100;phase.drop_objection(this);endtask
  endclass
endpackage
