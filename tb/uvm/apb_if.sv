interface apb_if(input logic PCLK);
    logic PRESETn, PSEL, PENABLE, PWRITE, PREADY, PSLVERR;
    logic [7:0] PADDR;
    logic [31:0] PWDATA, PRDATA;
endinterface
