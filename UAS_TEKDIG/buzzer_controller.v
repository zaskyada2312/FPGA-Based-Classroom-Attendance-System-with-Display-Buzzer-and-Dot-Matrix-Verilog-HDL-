// ============================================================
// File   : buzzer_controller.v
// Fungsi : Mengatur pola suara buzzer
//
// Masuk  = beep pendek 1 kali
// Keluar = beep pendek 2 kali
// Full   = beep panjang
// ============================================================

module buzzer_controller #(
    parameter CLK_FREQ = 50000000
)(
    input  wire clk,
    input  wire rst_n,
    input  wire trigger_masuk,
    input  wire trigger_keluar,
    input  wire trigger_full,
    output reg  buzzer
);

    localparam integer TONE_DIV = CLK_FREQ / 4000;  // sekitar 2 kHz
    localparam integer DUR_SHORT = CLK_FREQ / 10;   // 0.1 detik
    localparam integer DUR_GAP   = CLK_FREQ / 10;   // 0.1 detik
    localparam integer DUR_LONG  = CLK_FREQ / 2;    // 0.5 detik

    localparam IDLE       = 3'd0;
    localparam MASUK_BEEP = 3'd1;
    localparam KELUAR_B1  = 3'd2;
    localparam KELUAR_GAP = 3'd3;
    localparam KELUAR_B2  = 3'd4;
    localparam FULL_BEEP  = 3'd5;

    reg [2:0] state;
    reg [31:0] duration_count;
    reg [31:0] tone_count;
    reg tone;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tone_count <= 32'd0;
            tone <= 1'b0;
        end else begin
            if (tone_count >= TONE_DIV) begin
                tone_count <= 32'd0;
                tone <= ~tone;
            end else begin
                tone_count <= tone_count + 1'b1;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            duration_count <= 32'd0;
            buzzer <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    buzzer <= 1'b0;
                    duration_count <= 32'd0;

                    if (trigger_full)
                        state <= FULL_BEEP;
                    else if (trigger_masuk)
                        state <= MASUK_BEEP;
                    else if (trigger_keluar)
                        state <= KELUAR_B1;
                    else
                        state <= IDLE;
                end

                MASUK_BEEP: begin
                    buzzer <= tone;
                    if (duration_count < DUR_SHORT)
                        duration_count <= duration_count + 1'b1;
                    else begin
                        duration_count <= 32'd0;
                        state <= IDLE;
                    end
                end

                KELUAR_B1: begin
                    buzzer <= tone;
                    if (duration_count < DUR_SHORT)
                        duration_count <= duration_count + 1'b1;
                    else begin
                        duration_count <= 32'd0;
                        state <= KELUAR_GAP;
                    end
                end

                KELUAR_GAP: begin
                    buzzer <= 1'b0;
                    if (duration_count < DUR_GAP)
                        duration_count <= duration_count + 1'b1;
                    else begin
                        duration_count <= 32'd0;
                        state <= KELUAR_B2;
                    end
                end

                KELUAR_B2: begin
                    buzzer <= tone;
                    if (duration_count < DUR_SHORT)
                        duration_count <= duration_count + 1'b1;
                    else begin
                        duration_count <= 32'd0;
                        state <= IDLE;
                    end
                end

                FULL_BEEP: begin
                    buzzer <= tone;
                    if (duration_count < DUR_LONG)
                        duration_count <= duration_count + 1'b1;
                    else begin
                        duration_count <= 32'd0;
                        state <= IDLE;
                    end
                end

                default: begin
                    buzzer <= 1'b0;
                    duration_count <= 32'd0;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
