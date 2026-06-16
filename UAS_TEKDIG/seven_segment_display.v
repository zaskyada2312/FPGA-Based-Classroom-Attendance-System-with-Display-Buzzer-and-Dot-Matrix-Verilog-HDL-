// ============================================================
// File   : seven_segment_display.v
// Fungsi : Menampilkan nilai counter 00 sampai 20
// ============================================================

module seven_segment_display (
    input  wire [5:0] count,
    output wire [6:0] seg_tens,
    output wire [6:0] seg_ones
);

    reg [3:0] tens;
    reg [3:0] ones;

    always @(*) begin
        if (count >= 20) begin
            tens = 4'd2;
            ones = 4'd0;
        end else if (count >= 10) begin
            tens = 4'd1;
            ones = count - 10;
        end else begin
            tens = 4'd0;
            ones = count[3:0];
        end
    end

    seven_segment_decoder decoder_tens (
        .digit(tens),
        .seg(seg_tens)
    );

    seven_segment_decoder decoder_ones (
        .digit(ones),
        .seg(seg_ones)
    );

endmodule
