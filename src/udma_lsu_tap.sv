module udma_lsu_tap (
    input logic clk_i,
    input logic rstn_i,

    input logic en_i,

    input logic rx_valid_i,
    input logic [7:0] rx_data_i,
    input logic tx_busy_i,
    output logic tx_valid_o,
    output logic [7:0] tx_data_o,

    output logic req_o,
    input  logic gnt_i,
    output logic [31:0] addr_o,
    output logic [31:0] data_o,
    input  logic valid_i,
    input  logic [31:0] data_i
);

    enum logic [4:0] {
        IDLE,
        WADDR0,
        WADDR1,
        WADDR2,
        WADDR3,
        WDATA0,
        WDATA1,
        WDATA2,
        WDATA3,
        WREQ,
        WREQN,
        WGNT,
        WVALID,
        RADDR0,
        RADDR1,
        RADDR2,
        RADDR3,
        RREQ,
        RREQN,
        RGNT,
        RVALID,
        TDATA0,
        TDATA1,
        TDATA2,
        TDATA3
    } CS,NS;

    always_comb begin
        NS = CS;
        if (en_i == 1'b0) NS = IDLE;
        else begin
            if (rx_valid_i) begin
                case (CS)
                    IDLE : 
                        if (rx_data_i == 8'b0) NS = WADDR0;
                        else                   NS = RADDR0;
                    WADDR0 : NS = WADDR1;
                    WADDR1 : NS = WADDR2;
                    WADDR2 : NS = WADDR3;
                    WADDR3 : NS = WDATA0;
                    WDATA0 : NS = WDATA1;
                    WDATA1 : NS = WDATA2;
                    WDATA2 : NS = WDATA3;
                    WDATA3 : NS = WREQ;
                    RADDR0 : NS = RADDR1;
                    RADDR1 : NS = RADDR2;
                    RADDR2 : NS = RADDR3;
                    RADDR3 : NS = RREQ;
                    default : NS = CS;
                endcase
            end
            else begin
                case (CS)
                    WREQ:  NS = WREQN;
                    WREQN: if (gnt_i) NS = WVALID;
                           else       NS = WGNT;
                    WGNT:  if (gnt_i) NS = WVALID;
                    WVALID: if (valid_i) NS = TDATA3;
                    RREQ:  NS = RREQN;
                    RREQN: if (gnt_i) NS = RVALID;
                           else       NS = RGNT;
                    RGNT:  if (gnt_i) NS = RVALID;
                    RVALID: if (valid_i) NS = TDATA0;
                    
                    TDATA0: if (~tx_busy_i) NS = TDATA1;
                    TDATA1: if (~tx_busy_i) NS = TDATA2;
                    TDATA2: if (~tx_busy_i) NS = TDATA3;
                    TDATA3: if (~tx_busy_i) NS = IDLE;
                    default : NS = IDLE;
                endcase
            end
        end
    end

    logic [31:0] data_i_latch;

    always_comb begin
        req_o = (CS == RREQN || CS == RGNT);
        case (CS)
            TDATA0 : tx_data_o = data_i_latch[7:0];
            TDATA1 : tx_data_o = data_i_latch[15:8];
            TDATA2 : tx_data_o = data_i_latch[23:16];
            TDATA3 : tx_data_o = data_i_latch[31:24];
            default : tx_data_o = 8'b0;
        endcase
        tx_valid_o = (CS == TDATA0 && NS == TDATA1) ||
                     (CS == TDATA1 && NS == TDATA2) ||
                     (CS == TDATA2 && NS == TDATA3) ||
                     (CS == TDATA3 && NS == IDLE);
    end    

    
    
    always_ff @(posedge clk_i or negedge rstn_i) begin
        if (rstn_i == 1'b0) begin
            CS <= IDLE;
            addr_o <= 32'b0;
            data_o <= 32'b0;
            data_i_latch <= 32'b0;
        end
        else begin
            if(cfg_en_i)
               CS <= NS;
            else
               CS <= IDLE;

            data_o[7:0]   <= (rx_valid_i && (CS == WDATA0)) ? rx_data_i : data_o[7:0];
            data_o[15:8]  <= (rx_valid_i && (CS == WDATA1)) ? rx_data_i : data_o[15:8];
            data_o[23:16] <= (rx_valid_i && (CS == WDATA2)) ? rx_data_i : data_o[23:16];
            data_o[31:24] <= (rx_valid_i && (CS == WDATA3)) ? rx_data_i : data_o[31:24];

            addr_o[7:0]   <= (rx_valid_i && (CS == WADDR0 || CS == RADDR0)) ? rx_data_i : addr_o[7:0];
            addr_o[15:8]  <= (rx_valid_i && (CS == WADDR1 || CS == RADDR1)) ? rx_data_i : addr_o[15:8];
            addr_o[23:16] <= (rx_valid_i && (CS == WADDR2 || CS == RADDR2)) ? rx_data_i : addr_o[23:16];
            addr_o[31:24] <= (rx_valid_i && (CS == WADDR3 || CS == RADDR3)) ? rx_data_i : addr_o[31:24];

            data_i_latch <= valid_i ? data_i : data_i_latch;
        end
    end   

endmodule

