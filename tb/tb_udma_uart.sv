
module tb_udma_uart;
    logic clk;
    logic rstn;

    initial begin
        clk = 1'b0;
        forever #1ns clk = ~clk;
    end 

    initial begin
        rstn = 1'b1;
        #1ns;
        rstn = 1'b0;
        #4ns;
        rstn = 1'b1;
    end


    initial begin
        $fsdbDumpfile("top.fsdb");
        $fsdbDumpvars;
    end
    
    wire tx,busy;    
    logic cfg_en = 1'b0;
    logic [7:0] tx_data;
    logic tx_valid = 1'b0;
    wire tx_ready;    

    udma_uart_tx u_tx (
        .clk_i(clk),
        .rstn_i(rstn),
        .tx_o(tx),
        .busy_o(busy),
        .cfg_en_i(cfg_en),
        .cfg_div_i(16'h8), //clock division
        .cfg_parity_en_i(1'b0),
        .cfg_bits_i(2'b11),
        .cfg_stop_bits_i(1'b0),
        .tx_data_i(tx_data),
        .tx_valid_i(tx_valid),
        .tx_ready_o(tx_ready)
    );

    logic [7:0] rx_data;
    logic rx_valid;    
    
    always @(negedge clk) begin
        if (rx_valid) $display("[rx] %02X",rx_data);
    end

    udma_uart_rx u_rx (
        .clk_i(clk),
        .rstn_i(rstn),
        .rx_i(tx),
        .cfg_div_i(16'h8),
        .cfg_en_i(cfg_en),
        .cfg_parity_en_i(1'b0),
        .cfg_bits_i(2'b11),
        .cfg_stop_bits_i(1'b0),
        .busy_o(),
        .err_o(),
        .err_clr_i(1'b0),
        .rx_data_o(rx_data),
        .rx_valid_o(rx_valid),
        .rx_ready_i(1'b1)
    );

    task uart_tx;
        input [7:0] data;
        begin
            @(posedge clk);
            while(busy) @(posedge clk);
            tx_data = data;
            @(posedge clk);
            tx_valid = 1'b1;
            @(posedge clk);
            tx_valid = 1'b0;            
        end
    endtask

    initial begin
        @(posedge rstn);
        @(posedge clk);
        cfg_en = 1'b1;
        repeat(10) @(posedge clk);
        uart_tx(8'h12);
        uart_tx(8'h23);
        repeat(1000) @(posedge clk);
        $finish;
    end

endmodule 

