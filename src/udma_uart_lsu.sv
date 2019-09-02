module udma_uart_lsu (
    input  logic            clk_i,
    input  logic            rstn_i,
    input  logic            cfg_en_i,
    input  logic [15:0]     cfg_div_i,
    input  logic            cfg_parity_en_i,
    input  logic  [1:0]     cfg_bits_i,
    input  logic            cfg_stop_bits_i,
    
    output logic            req_o,
    input  logic            gnt_i,
    output logic [31:0]     addr_o,
    output logic [31:0]     data_o,
    input  logic            valid_i,
    input  logic [31:0]     data_i,

    input  logic            rx_i,
    output logic            tx_o  
);

    logic busy;
    logic [7:0] tx_data;
    logic tx_valid;
    logic [7:0] rx_data;
    logic rx_valid;
    

    udma_uart_tx u_tx (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .tx_o(tx_o),
        .busy_o(busy),
        .cfg_en_i(cfg_en_i),
        .cfg_div_i(cfg_div_i), //clock division
        .cfg_parity_en_i(cfg_parity_en_i),
        .cfg_bits_i(cfg_bits_i),
        .cfg_stop_bits_i(cfg_stop_bits_i),
        .tx_data_i(tx_data),
        .tx_valid_i(tx_valid),
        .tx_ready_o()
    );

    udma_uart_rx u_rx (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .rx_i(tx_i),
        .cfg_div_i(cfg_div_i),
        .cfg_en_i(cfg_en_i),
        .cfg_parity_en_i(cfg_parity_en_i),
        .cfg_bits_i(cfg_bits_i),
        .cfg_stop_bits_i(cfg_stop_bits_i),
        .busy_o(),
        .err_o(),
        .err_clr_i(1'b0),
        .rx_data_o(rx_data),
        .rx_valid_o(rx_valid),
        .rx_ready_i(1'b1)
    );   

    udma_lsu_tap (
        .clk_i(clk_i),
        .rstn_i(rstn_i),

        .en_i(cfg_en_i),

        .rx_valid_i(rx_valid),
        .rx_data_i(rx_data),
        .tx_busy_i(busy),
        .tx_valid_o(tx_valid),
        .tx_data_o(tx_data),

        .req_o(req_o),
        .gnt_i(gnt_i),
        .addr_o(addr_o),
        .data_o(data_o),
        .valid_i(valid_i),
        .data_i(data_i)
    );

endmodule

