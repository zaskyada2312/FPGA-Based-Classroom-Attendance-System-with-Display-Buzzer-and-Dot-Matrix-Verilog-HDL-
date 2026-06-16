// ============================================================
// File   : dot_matrix_running_text.v
// Fungsi : Menampilkan running text pada dot matrix 8x8
//
// Teks yang tersedia:
// HADIR, KELUAR, AMAN, HALF, FULL
//
// Asumsi:
// row aktif LOW
// col aktif HIGH
//
// Jika huruf masih terbalik atas-bawah, ubah bagian row:
// row = ~(8'b00000001 << scan_index);
// menjadi:
// row = ~(8'b10000000 >> scan_index);
// ============================================================

module dot_matrix_running_text #(
    parameter CLK_FREQ = 50000000
)(
    input  wire clk,
    input  wire rst_n,

    input  wire trigger_masuk,
    input  wire trigger_keluar,
    input  wire trigger_full,

    input  wire [1:0] status,

    output reg  [7:0] row,
    output reg  [7:0] col
);

    // ========================================================
    // Kode pesan
    // ========================================================
    localparam MSG_AMAN   = 3'd0;
    localparam MSG_HALF   = 3'd1;
    localparam MSG_FULL   = 3'd2;
    localparam MSG_HADIR  = 3'd3;
    localparam MSG_KELUAR = 3'd4;

    localparam SHOW_STATUS = 1'b0;
    localparam SHOW_EVENT  = 1'b1;

    // ========================================================
    // Kecepatan scanning dan running text
    // ========================================================
    localparam integer SCAN_DIV   = CLK_FREQ / 8000;
    localparam integer SCROLL_DIV = CLK_FREQ / 8;

    reg display_state;
    reg [2:0] current_msg;
    reg [2:0] status_msg;

    reg [31:0] scan_counter;
    reg [2:0] scan_index;

    reg [31:0] scroll_counter;
    reg [7:0] scroll_pos;

    reg [7:0] max_scroll;
    reg message_done;

    integer i;

    reg [7:0] temp_col;
    reg [7:0] virtual_col;
    reg [3:0] char_index;
    reg [2:0] col_in_char;
    reg [7:0] char_code;
    reg pixel_on;

    // ========================================================
    // Mapping status ke pesan
    // status 0 = AMAN
    // status 1 = HALF
    // status 2 = FULL
    // ========================================================
    always @(*) begin
        case (status)
            2'd0: status_msg = MSG_AMAN;
            2'd1: status_msg = MSG_HALF;
            2'd2: status_msg = MSG_FULL;
            default: status_msg = MSG_AMAN;
        endcase
    end

    // ========================================================
    // Panjang running text
    // Rumus:
    // 8 kolom kosong awal + jumlah huruf * 6 + 8 kolom kosong akhir
    // 6 = 5 kolom huruf + 1 kolom spasi
    // ========================================================
    always @(*) begin
        case (current_msg)
            MSG_AMAN:   max_scroll = 8 + (9 * 6) + 8; 
            MSG_HALF:   max_scroll = 8 + (4 * 6) + 8;
            MSG_FULL:   max_scroll = 8 + (4 * 6) + 8;
            MSG_HADIR:  max_scroll = 8 + (5 * 6) + 8;
            MSG_KELUAR: max_scroll = 8 + (6 * 6) + 8;
            default:    max_scroll = 8 + (4 * 6) + 8;
        endcase
    end

    // ========================================================
    // Kontrol pesan
    // Ketika PB masuk ditekan  -> tampil HADIR
    // Ketika PB keluar ditekan -> tampil KELUAR
    // Setelah itu kembali menampilkan status ruangan
    // ========================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            display_state  <= SHOW_STATUS;
            current_msg    <= MSG_AMAN;
            scroll_pos     <= 8'd0;
            scroll_counter <= 32'd0;
            message_done   <= 1'b0;
        end else begin
            message_done <= 1'b0;

            if (trigger_masuk) begin
                display_state  <= SHOW_EVENT;
                current_msg    <= MSG_HADIR;
                scroll_pos     <= 8'd0;
                scroll_counter <= 32'd0;
            end else if (trigger_keluar) begin
                display_state  <= SHOW_EVENT;
                current_msg    <= MSG_KELUAR;
                scroll_pos     <= 8'd0;
                scroll_counter <= 32'd0;
            end else if (trigger_full) begin
                display_state  <= SHOW_STATUS;
                current_msg    <= MSG_FULL;
                scroll_pos     <= 8'd0;
                scroll_counter <= 32'd0;
            end else begin
                if (scroll_counter >= SCROLL_DIV) begin
                    scroll_counter <= 32'd0;

                    if (scroll_pos >= max_scroll) begin
                        message_done <= 1'b1;
                        scroll_pos <= 8'd0;

                        if (display_state == SHOW_EVENT) begin
                            display_state <= SHOW_STATUS;
                            current_msg <= status_msg;
                        end else begin
                            current_msg <= status_msg;
                        end
                    end else begin
                        scroll_pos <= scroll_pos + 1'b1;
                    end
                end else begin
                    scroll_counter <= scroll_counter + 1'b1;
                end
            end
        end
    end

    // ========================================================
    // Scanning row dot matrix
    // ========================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scan_counter <= 32'd0;
            scan_index <= 3'd0;
        end else begin
            if (scan_counter >= SCAN_DIV) begin
                scan_counter <= 32'd0;
                scan_index <= scan_index + 1'b1;
            end else begin
                scan_counter <= scan_counter + 1'b1;
            end
        end
    end

    // ========================================================
    // Output row dan column
    //
    // row aktif LOW
    // col aktif HIGH
    //
    // Bagian penting:
    // temp_col[i] = pixel_on;
    // Ini supaya huruf tidak terbalik kiri-kanan.
    // ========================================================
    always @(*) begin
        row = ~(8'b00000001 << scan_index);
        temp_col = 8'b00000000;

        for (i = 0; i < 8; i = i + 1) begin
            virtual_col = scroll_pos + i[7:0];

            if (virtual_col < 8) begin
                pixel_on = 1'b0;
            end else begin
                virtual_col = virtual_col - 8;
                char_index = virtual_col / 6;
                col_in_char = virtual_col % 6;

                if (col_in_char == 5) begin
                    pixel_on = 1'b0;
                end else begin
                    char_code = get_char(current_msg, char_index);
                    pixel_on = get_pixel(char_code, scan_index, col_in_char);
                end
            end

            // Perbaikan utama agar alphabet tidak terbalik kiri-kanan
            temp_col[i] = pixel_on;
        end

        col = temp_col;
    end

    // ========================================================
    // Function get_char
    // Mengambil huruf berdasarkan pesan dan index huruf
    // ========================================================
    function [7:0] get_char;
        input [2:0] msg;
        input [3:0] index;
        begin
            get_char = " ";

            case (msg)
                MSG_AMAN: begin
    case (index)
        0: get_char = "A";
        1: get_char = "V";
        2: get_char = "A";
        3: get_char = "I";
        4: get_char = "L";
        5: get_char = "A";
        6: get_char = "B";
        7: get_char = "L";
        8: get_char = "E";
        default: get_char = " ";
    endcase
end

                MSG_HALF: begin
                    case (index)
                        0: get_char = "H";
                        1: get_char = "A";
                        2: get_char = "L";
                        3: get_char = "F";
                        default: get_char = " ";
                    endcase
                end

                MSG_FULL: begin
                    case (index)
                        0: get_char = "F";
                        1: get_char = "U";
                        2: get_char = "L";
                        3: get_char = "L";
                        default: get_char = " ";
                    endcase
                end

                MSG_HADIR: begin
                    case (index)
                        0: get_char = "H";
                        1: get_char = "A";
                        2: get_char = "D";
                        3: get_char = "I";
                        4: get_char = "R";
                        default: get_char = " ";
                    endcase
                end

                MSG_KELUAR: begin
                    case (index)
                        0: get_char = "K";
                        1: get_char = "E";
                        2: get_char = "L";
                        3: get_char = "U";
                        4: get_char = "A";
                        5: get_char = "R";
                        default: get_char = " ";
                    endcase
                end

                default: begin
                    get_char = " ";
                end
            endcase
        end
    endfunction

    // ========================================================
    // Function get_pixel
    // Font huruf ukuran 5x7
    // ========================================================
    function get_pixel;
        input [7:0] ch;
        input [2:0] row_index;
        input [2:0] col_index;

        reg [4:0] row_pattern;

        begin
            row_pattern = 5'b00000;

            case (ch)
				
				"B": begin
    case (row_index)
        0: row_pattern = 5'b11110;
        1: row_pattern = 5'b10001;
        2: row_pattern = 5'b10001;
        3: row_pattern = 5'b11110;
        4: row_pattern = 5'b10001;
        5: row_pattern = 5'b10001;
        6: row_pattern = 5'b11110;
        default: row_pattern = 5'b00000;
    endcase
end

"V": begin
    case (row_index)
        0: row_pattern = 5'b10001;
        1: row_pattern = 5'b10001;
        2: row_pattern = 5'b10001;
        3: row_pattern = 5'b10001;
        4: row_pattern = 5'b10001;
        5: row_pattern = 5'b01010;
        6: row_pattern = 5'b00100;
        default: row_pattern = 5'b00000;
    endcase
end

                "A": begin
                    case (row_index)
                        0: row_pattern = 5'b01110;
                        1: row_pattern = 5'b10001;
                        2: row_pattern = 5'b10001;
                        3: row_pattern = 5'b11111;
                        4: row_pattern = 5'b10001;
                        5: row_pattern = 5'b10001;
                        6: row_pattern = 5'b10001;
                        default: row_pattern = 5'b00000;
                    endcase
                end

                "D": begin
                    case (row_index)
                        0: row_pattern = 5'b11110;
                        1: row_pattern = 5'b10001;
                        2: row_pattern = 5'b10001;
                        3: row_pattern = 5'b10001;
                        4: row_pattern = 5'b10001;
                        5: row_pattern = 5'b10001;
                        6: row_pattern = 5'b11110;
                        default: row_pattern = 5'b00000;
                    endcase
                end

                "E": begin
                    case (row_index)
                        0: row_pattern = 5'b11111;
                        1: row_pattern = 5'b10000;
                        2: row_pattern = 5'b10000;
                        3: row_pattern = 5'b11110;
                        4: row_pattern = 5'b10000;
                        5: row_pattern = 5'b10000;
                        6: row_pattern = 5'b11111;
                        default: row_pattern = 5'b00000;
                    endcase
                end

                "F": begin
                    case (row_index)
                        0: row_pattern = 5'b11111;
                        1: row_pattern = 5'b10000;
                        2: row_pattern = 5'b10000;
                        3: row_pattern = 5'b11110;
                        4: row_pattern = 5'b10000;
                        5: row_pattern = 5'b10000;
                        6: row_pattern = 5'b10000;
                        default: row_pattern = 5'b00000;
                    endcase
                end

                "H": begin
                    case (row_index)
                        0: row_pattern = 5'b10001;
                        1: row_pattern = 5'b10001;
                        2: row_pattern = 5'b10001;
                        3: row_pattern = 5'b11111;
                        4: row_pattern = 5'b10001;
                        5: row_pattern = 5'b10001;
                        6: row_pattern = 5'b10001;
                        default: row_pattern = 5'b00000;
                    endcase
                end

                "I": begin
                    case (row_index)
                        0: row_pattern = 5'b11111;
                        1: row_pattern = 5'b00100;
                        2: row_pattern = 5'b00100;
                        3: row_pattern = 5'b00100;
                        4: row_pattern = 5'b00100;
                        5: row_pattern = 5'b00100;
                        6: row_pattern = 5'b11111;
                        default: row_pattern = 5'b00000;
                    endcase
                end

                "K": begin
                    case (row_index)
                        0: row_pattern = 5'b10001;
                        1: row_pattern = 5'b10010;
                        2: row_pattern = 5'b10100;
                        3: row_pattern = 5'b11000;
                        4: row_pattern = 5'b10100;
                        5: row_pattern = 5'b10010;
                        6: row_pattern = 5'b10001;
                        default: row_pattern = 5'b00000;
                    endcase
                end

                "L": begin
                    case (row_index)
                        0: row_pattern = 5'b10000;
                        1: row_pattern = 5'b10000;
                        2: row_pattern = 5'b10000;
                        3: row_pattern = 5'b10000;
                        4: row_pattern = 5'b10000;
                        5: row_pattern = 5'b10000;
                        6: row_pattern = 5'b11111;
                        default: row_pattern = 5'b00000;
                    endcase
                end

                "M": begin
                    case (row_index)
                        0: row_pattern = 5'b10001;
                        1: row_pattern = 5'b11011;
                        2: row_pattern = 5'b10101;
                        3: row_pattern = 5'b10101;
                        4: row_pattern = 5'b10001;
                        5: row_pattern = 5'b10001;
                        6: row_pattern = 5'b10001;
                        default: row_pattern = 5'b00000;
                    endcase
                end

                "N": begin
                    case (row_index)
                        0: row_pattern = 5'b10001;
                        1: row_pattern = 5'b11001;
                        2: row_pattern = 5'b10101;
                        3: row_pattern = 5'b10011;
                        4: row_pattern = 5'b10001;
                        5: row_pattern = 5'b10001;
                        6: row_pattern = 5'b10001;
                        default: row_pattern = 5'b00000;
                    endcase
                end

                "R": begin
                    case (row_index)
                        0: row_pattern = 5'b11110;
                        1: row_pattern = 5'b10001;
                        2: row_pattern = 5'b10001;
                        3: row_pattern = 5'b11110;
                        4: row_pattern = 5'b10100;
                        5: row_pattern = 5'b10010;
                        6: row_pattern = 5'b10001;
                        default: row_pattern = 5'b00000;
                    endcase
                end

                "U": begin
                    case (row_index)
                        0: row_pattern = 5'b10001;
                        1: row_pattern = 5'b10001;
                        2: row_pattern = 5'b10001;
                        3: row_pattern = 5'b10001;
                        4: row_pattern = 5'b10001;
                        5: row_pattern = 5'b10001;
                        6: row_pattern = 5'b01110;
                        default: row_pattern = 5'b00000;
                    endcase
                end

                default: begin
                    row_pattern = 5'b00000;
                end

            endcase

            get_pixel = row_pattern[4 - col_index];
        end
    endfunction

endmodule