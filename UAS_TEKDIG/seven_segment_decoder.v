// ============================================================
// File   : seven_segment_decoder.v
// Fungsi : Decoder angka 0-9 ke 7-segment
//
// Asumsi 7-segment aktif LOW
// seg[6:0] = {a,b,c,d,e,f,g}
// Jika board aktif HIGH, output seg bisa dibalik/invert.
// ============================================================

module seven_segment_decoder (
    input  wire [3:0] digit,
    output reg  [6:0] seg
);

    always @(*) begin
        case (digit)
            4'd0: seg = 7'b0000001;
            4'd1: seg = 7'b1001111;
            4'd2: seg = 7'b0010010;
            4'd3: seg = 7'b0000110;
            4'd4: seg = 7'b1001100;
            4'd5: seg = 7'b0100100;
            4'd6: seg = 7'b0100000;
            4'd7: seg = 7'b0001111;
            4'd8: seg = 7'b0000000;
            4'd9: seg = 7'b0000100;
            default: seg = 7'b1111111;
        endcase
    end

endmodule
