// ============================================================
// File   : up_down_counter.v
// Fungsi : Counter jumlah orang masuk dan keluar
// ============================================================

module up_down_counter #(
    parameter MAX_CAPACITY = 20
)(
    input  wire clk,
    input  wire rst_n,
    input  wire inc,
    input  wire dec,
    output reg  [5:0] count
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 6'd0;
        end else begin
            if (inc && !dec) begin
                if (count < MAX_CAPACITY)
                    count <= count + 1'b1;
                else
                    count <= count;
            end else if (dec && !inc) begin
                if (count > 0)
                    count <= count - 1'b1;
                else
                    count <= count;
            end else begin
                count <= count;
            end
        end
    end

endmodule
