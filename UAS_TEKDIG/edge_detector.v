// ============================================================
// File   : edge_detector.v
// Fungsi : Membuat pulse 1 clock saat input berubah dari 0 ke 1
// ============================================================

module edge_detector (
    input  wire clk,
    input  wire rst_n,
    input  wire signal_in,
    output wire pulse_out
);

    reg signal_delay;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            signal_delay <= 1'b0;
        else
            signal_delay <= signal_in;
    end

    assign pulse_out = signal_in & ~signal_delay;

endmodule
