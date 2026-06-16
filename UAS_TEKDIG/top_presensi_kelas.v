// ============================================================
// File    : top_presensi_kelas.v
// Project : Sistem Presensi Ruangan Kelas Berbasis FPGA
// Fungsi  : Top level untuk menghubungkan semua modul
// ============================================================

module top_presensi_kelas #(
    parameter CLK_FREQ     = 50000000,
    parameter MAX_CAPACITY = 20
)(
    input  wire clk,
    input  wire rst_n,

    // Push button diasumsikan aktif LOW
    input  wire pb_masuk,
    input  wire pb_keluar,

    // 7-segment multiplex, aktif LOW
    output wire [6:0] seg,
    output wire [3:0] en,

    // LED indikator
    output wire led_aman,
    output wire led_half,
    output wire led_full,

    // Buzzer
    output wire buzzer,

    // Dot matrix 8x8
    // row aktif LOW, col aktif HIGH
    output wire [7:0] matrix_row,
    output wire [7:0] matrix_col
);

    // Tombol aktif LOW diubah menjadi aktif HIGH
    wire masuk_raw  = ~pb_masuk;
    wire keluar_raw = ~pb_keluar;

    wire masuk_db;
    wire keluar_db;

    wire masuk_pulse;
    wire keluar_pulse;

    wire [5:0] count;
    wire [1:0] status;

    wire valid_masuk;
    wire valid_keluar;
    wire full_alarm;

    assign valid_masuk  = masuk_pulse  && (count < MAX_CAPACITY);
    assign valid_keluar = keluar_pulse && (count > 0);
    assign full_alarm   = masuk_pulse  && (count >= MAX_CAPACITY);

    debounce #(
        .CLK_FREQ(CLK_FREQ),
        .DEBOUNCE_MS(20)
    ) debounce_masuk (
        .clk(clk),
        .rst_n(rst_n),
        .button_in(masuk_raw),
        .button_out(masuk_db)
    );

    debounce #(
        .CLK_FREQ(CLK_FREQ),
        .DEBOUNCE_MS(20)
    ) debounce_keluar (
        .clk(clk),
        .rst_n(rst_n),
        .button_in(keluar_raw),
        .button_out(keluar_db)
    );

    edge_detector edge_masuk (
        .clk(clk),
        .rst_n(rst_n),
        .signal_in(masuk_db),
        .pulse_out(masuk_pulse)
    );

    edge_detector edge_keluar (
        .clk(clk),
        .rst_n(rst_n),
        .signal_in(keluar_db),
        .pulse_out(keluar_pulse)
    );

    up_down_counter #(
        .MAX_CAPACITY(MAX_CAPACITY)
    ) counter_presensi (
        .clk(clk),
        .rst_n(rst_n),
        .inc(valid_masuk),
        .dec(valid_keluar),
        .count(count)
    );

    status_logic status_ruangan (
        .count(count),
        .status(status),
        .led_aman(led_aman),
        .led_half(led_half),
        .led_full(led_full)
    );

    seven_segment_multiplex display_angka (
        .clk(clk),
        .rst_n(rst_n),
        .count(count),
        .seg(seg),
        .en(en)
    );

    buzzer_controller #(
        .CLK_FREQ(CLK_FREQ)
    ) buzzer_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .trigger_masuk(valid_masuk),
        .trigger_keluar(valid_keluar),
        .trigger_full(full_alarm),
        .buzzer(buzzer)
    );

    dot_matrix_running_text #(
        .CLK_FREQ(CLK_FREQ)
    ) dot_matrix_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .trigger_masuk(valid_masuk),
        .trigger_keluar(valid_keluar),
        .trigger_full(full_alarm),
        .status(status),
        .row(matrix_row),
        .col(matrix_col)
    );

endmodule