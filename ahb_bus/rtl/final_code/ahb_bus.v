`timescale 1ns/1ps

module ahb_bus (

    input         hclk,
    input         hresetn,

    ////////////////////////////////////////////////////////////
    // MASTER SIDE
    ////////////////////////////////////////////////////////////
    input  [31:0] m_haddr,
    input         m_hwrite,
    input  [2:0]  m_hsize,
    input  [2:0]  m_hburst,
    input  [3:0]  m_hprot,
    input  [1:0]  m_htrans,
    input         m_hmastlock,
    input  [31:0] m_hwdata,

    output [31:0] m_hrdata,
    output        m_hready,
    output [1:0]  m_hresp,

    ////////////////////////////////////////////////////////////
    // SLAVE SIDE (AHB-APB BRIDGE)
    ////////////////////////////////////////////////////////////
    output [31:0] s_haddr,
    output        s_hwrite,
    output [2:0]  s_hsize,
    output [2:0]  s_hburst,
    output [3:0]  s_hprot,
    output [1:0]  s_htrans,
    output        s_hmastlock,
    output [31:0] s_hwdata,

    input  [31:0] s_hrdata,
    input         s_hready,
    input  [1:0]  s_hresp
);

////////////////////////////////////////////////////////////
// SIMPLE PASS-THROUGH BUS
////////////////////////////////////////////////////////////

// Address/control signals → Slave
assign s_haddr     = m_haddr;
assign s_hwrite    = m_hwrite;
assign s_hsize     = m_hsize;
assign s_hburst    = m_hburst;
assign s_hprot     = m_hprot;
assign s_htrans    = m_htrans;
assign s_hmastlock = m_hmastlock;
assign s_hwdata    = m_hwdata;

// Response signals → Master
assign m_hrdata = s_hrdata;
assign m_hready = s_hready;
assign m_hresp  = s_hresp;

endmodule
