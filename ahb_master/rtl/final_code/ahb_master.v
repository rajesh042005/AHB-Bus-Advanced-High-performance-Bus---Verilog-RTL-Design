`timescale 1ns/1ps

module ahb_master (

    input         hclk,
    input         hresetn,

    // FROM SLAVE
    input         hready,
    input  [1:0]  hresp,
    input  [31:0] hrdata,

    // TO BUS
    output reg [31:0] haddr,
    output reg        hwrite,
    output reg [2:0]  hsize,
    output reg [2:0]  hburst,
    output reg [3:0]  hprot,
    output reg [1:0]  htrans,
    output reg        hmastlock,
    output reg [31:0] hwdata
);

////////////////////////////////////////////////////////////
// HTRANS
////////////////////////////////////////////////////////////
parameter IDLE   = 2'b00;
parameter NONSEQ = 2'b10;

////////////////////////////////////////////////////////////
// STATES
////////////////////////////////////////////////////////////
parameter S_IDLE  = 2'd0;
parameter S_WRITE = 2'd1;
parameter S_READ  = 2'd2;

////////////////////////////////////////////////////////////
// INTERNAL
////////////////////////////////////////////////////////////
reg [1:0] state;
reg [3:0] count;

////////////////////////////////////////////////////////////
// MAIN FSM
////////////////////////////////////////////////////////////
always @(posedge hclk or negedge hresetn) begin
    if (!hresetn) begin
        state      <= S_IDLE;
        haddr      <= 32'h0000_0000;
        hwrite     <= 1'b0;
        hsize      <= 3'b010; // WORD
        hburst     <= 3'b000; // SINGLE
        hprot      <= 4'b0011;
        htrans     <= IDLE;
        hmastlock  <= 1'b0;
        hwdata     <= 32'd0;
        count      <= 0;
    end
    else begin

        case (state)

        ////////////////////////////////////////////////////
        // IDLE → START WRITE
        ////////////////////////////////////////////////////
        S_IDLE: begin
            if (hready) begin
                haddr  <= 32'h0000_0000;   // RAM BASE
                hwdata <= 32'hA5A50000;    // initial data
                hwrite <= 1'b1;
                htrans <= NONSEQ;
                count  <= 0;
                state  <= S_WRITE;
            end
        end

        ////////////////////////////////////////////////////
        // WRITE PHASE
        ////////////////////////////////////////////////////
        S_WRITE: begin
            if (hready) begin
                haddr  <= haddr + 4;                 // next word
                hwdata <= hwdata + 1;               // change data
                hwrite <= 1'b1;
                htrans <= NONSEQ;

                count <= count + 1;

                if (count == 4) begin
                    state <= S_READ;
                    haddr <= 32'h0000_0000;         // restart read
                end
            end
        end

        ////////////////////////////////////////////////////
        // READ PHASE
        ////////////////////////////////////////////////////
        S_READ: begin
            if (hready) begin
                haddr  <= haddr + 4;
                hwrite <= 1'b0;
                htrans <= NONSEQ;

                count <= count + 1;

                if (count == 8) begin
                    htrans <= IDLE;
                    state  <= S_READ; // stay here
                end
            end
        end

        default: state <= S_IDLE;

        endcase
    end
end

endmodule
