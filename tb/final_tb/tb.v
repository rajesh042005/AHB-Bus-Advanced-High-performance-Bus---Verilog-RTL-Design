`timescale 1ns/1ps

module tb_ahb;

////////////////////////////////////////////////////////////
// CLOCK + RESET
////////////////////////////////////////////////////////////
reg hclk;
reg hresetn;

initial begin
    hclk = 0;
    forever #5 hclk = ~hclk;
end

initial begin
    hresetn = 0;
    #20;
    hresetn = 1;
end

////////////////////////////////////////////////////////////
// WAVEFORM DUMP
////////////////////////////////////////////////////////////
initial begin
    $dumpfile("ahb_wave.vcd");
    $dumpvars(0, tb_ahb);
end

////////////////////////////////////////////////////////////
// MASTER <-> BUS
////////////////////////////////////////////////////////////
wire [31:0] haddr;
wire        hwrite;
wire [2:0]  hsize;
wire [2:0]  hburst;
wire [3:0]  hprot;
wire [1:0]  htrans;
wire        hmastlock;
wire [31:0] hwdata;

wire [31:0] hrdata;
wire        hready;
wire [1:0]  hresp;

////////////////////////////////////////////////////////////
// BUS <-> SLAVE
////////////////////////////////////////////////////////////
wire [31:0] s_haddr;
wire        s_hwrite;
wire [2:0]  s_hsize;
wire [2:0]  s_hburst;
wire [3:0]  s_hprot;
wire [1:0]  s_htrans;
wire        s_hmastlock;
wire [31:0] s_hwdata;

reg  [31:0] s_hrdata;
reg         s_hready;
reg  [1:0]  s_hresp;

////////////////////////////////////////////////////////////
// DUT
////////////////////////////////////////////////////////////
ahb_master u_master (
    .hclk(hclk),
    .hresetn(hresetn),
    .hready(hready),
    .hresp(hresp),
    .hrdata(hrdata),

    .haddr(haddr),
    .hwrite(hwrite),
    .hsize(hsize),
    .hburst(hburst),
    .hprot(hprot),
    .htrans(htrans),
    .hmastlock(hmastlock),
    .hwdata(hwdata)
);

ahb_bus u_bus (
    .hclk(hclk),
    .hresetn(hresetn),

    .m_haddr(haddr),
    .m_hwrite(hwrite),
    .m_hsize(hsize),
    .m_hburst(hburst),
    .m_hprot(hprot),
    .m_htrans(htrans),
    .m_hmastlock(hmastlock),
    .m_hwdata(hwdata),

    .m_hrdata(hrdata),
    .m_hready(hready),
    .m_hresp(hresp),

    .s_haddr(s_haddr),
    .s_hwrite(s_hwrite),
    .s_hsize(s_hsize),
    .s_hburst(s_hburst),
    .s_hprot(s_hprot),
    .s_htrans(s_htrans),
    .s_hmastlock(s_hmastlock),
    .s_hwdata(s_hwdata),

    .s_hrdata(s_hrdata),
    .s_hready(s_hready),
    .s_hresp(s_hresp)
);

////////////////////////////////////////////////////////////
// SIMPLE MEMORY
////////////////////////////////////////////////////////////
reg [31:0] mem [0:255];
integer i;

initial begin
    for (i = 0; i < 256; i = i + 1)
        mem[i] = 0;
end

////////////////////////////////////////////////////////////
// SLAVE MODEL
////////////////////////////////////////////////////////////
always @(posedge hclk) begin

    if (!hresetn) begin
        s_hready <= 1;
        s_hresp  <= 2'b00;
        s_hrdata <= 0;
    end
    else begin

        // Default
        s_hready <= 1;
        s_hresp  <= 2'b00;

        ////////////////////////////////////////////////
        // WAIT STATE (for addr range)
        ////////////////////////////////////////////////
        if (s_haddr[5:2] == 4'h3)
            s_hready <= 0;

        ////////////////////////////////////////////////
        // WRITE
        ////////////////////////////////////////////////
        if (s_hwrite && s_htrans == 2'b10 && s_hready)
            mem[s_haddr[9:2]] <= s_hwdata;

        ////////////////////////////////////////////////
        // READ
        ////////////////////////////////////////////////
        if (!s_hwrite && s_htrans == 2'b10 && s_hready)
            s_hrdata <= mem[s_haddr[9:2]];

        ////////////////////////////////////////////////
        // ERROR
        ////////////////////////////////////////////////
        if (s_haddr[9:2] == 8'hFF)
            s_hresp <= 2'b01;

    end
end

////////////////////////////////////////////////////////////
// MONITOR
////////////////////////////////////////////////////////////
initial begin
    $monitor("T=%0t | ADDR=%h | WR=%b | WDATA=%h | RDATA=%h | READY=%b | RESP=%b",
        $time, s_haddr, s_hwrite, s_hwdata, s_hrdata, s_hready, s_hresp);
end

////////////////////////////////////////////////////////////
// SIM END
////////////////////////////////////////////////////////////
initial begin
    #500 $finish;
end

endmodule
