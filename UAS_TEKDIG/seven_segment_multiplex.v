module seven_segment_multiplex (
    input wire clk,
    input wire rst_n,
    input wire [5:0] count,

    output reg [6:0] seg,
    output reg [3:0] en
);

    reg [15:0] refresh_counter;
    reg select_digit;

    reg [3:0] tens;
    reg [3:0] ones;
    reg [3:0] bcd;

    // Memisahkan angka puluhan dan satuan
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

    // Refresh multiplex 2 digit
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            refresh_counter <= 16'd0;
            select_digit <= 1'b0;
        end else begin
            if (refresh_counter >= 16'd50000) begin
                refresh_counter <= 16'd0;
                select_digit <= ~select_digit;
            end else begin
                refresh_counter <= refresh_counter + 1'b1;
            end
        end
    end

    // Pilih digit aktif
    // en aktif LOW
    always @(*) begin
       case (select_digit)
    1'b0: begin
        en = 4'b1110;   // digit pertama
        bcd = tens;     // puluhan
    end

    1'b1: begin
        en = 4'b1101;   // digit kedua
        bcd = ones;     // satuan
    end
endcase
    end

    // Decoder BCD ke 7-segment aktif LOW
    // Pola ini mengikuti kode lama kamu yang sudah benar
    always @(*) begin
        case (bcd)
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